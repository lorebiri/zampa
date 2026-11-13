-- Lulù: promemoria Web Push (web app e iPhone con l'app sulla schermata Home).
-- Rieseguibile. Coincide con la sezione 3 di supabase/schema.sql.
--
-- L'app (lib/sync/push_reminders.dart) salva l'iscrizione push del browser e,
-- a ogni modifica, sostituisce i propri promemoria in coda. La Edge Function
-- supabase/functions/invia-promemoria, lanciata ogni minuto da pg_cron,
-- preleva quelli scaduti e li invia. Nessuno legge le tabelle direttamente:
-- solo le funzioni qui sotto (gli utenti) e il ruolo di servizio (l'invio).

begin;

-- 3.1 Tabelle ------------------------------------------------------------------

create table if not exists public.push_subscriptions (
  endpoint text primary key check (endpoint ~ '^https://' and length(endpoint) <= 1000),
  user_id uuid not null references auth.users (id) on delete cascade,
  p256dh text not null check (length(p256dh) <= 200),
  auth text not null check (length(auth) <= 100),
  created_at timestamptz not null default now(),
  last_ok_at timestamptz
);
create index if not exists push_subscriptions_user on public.push_subscriptions (user_id);

create table if not exists public.push_queue (
  user_id uuid not null references auth.users (id) on delete cascade,
  id integer not null,
  urgent boolean not null default false,
  due_at timestamptz not null,
  title text not null check (length(title) <= 200),
  body text not null check (length(body) <= 1000),
  primary key (user_id, id, urgent)
);
create index if not exists push_queue_due on public.push_queue (due_at);

alter table public.push_subscriptions enable row level security;
alter table public.push_queue enable row level security;
-- Nessuna policy: per anon e authenticated le tabelle sono chiuse.
revoke all on public.push_subscriptions from anon, authenticated;
revoke all on public.push_queue from anon, authenticated;

-- 3.2 Funzioni per l'app (utente collegato) ------------------------------------

create or replace function public.registra_dispositivo_push(
  p_endpoint text, p_p256dh text, p_auth text
) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'serve l''accesso';
  end if;
  if (select count(*) from public.push_subscriptions
      where user_id = auth.uid() and endpoint <> p_endpoint) >= 10 then
    raise exception 'troppi dispositivi';
  end if;
  insert into public.push_subscriptions (endpoint, user_id, p256dh, auth)
  values (p_endpoint, auth.uid(), p_p256dh, p_auth)
  on conflict (endpoint) do update
    set user_id = excluded.user_id, p256dh = excluded.p256dh,
        auth = excluded.auth, created_at = now();
end $$;

create or replace function public.rimuovi_dispositivo_push(p_endpoint text)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'serve l''accesso';
  end if;
  delete from public.push_subscriptions
  where endpoint = p_endpoint and user_id = auth.uid();
  -- Senza più dispositivi, la coda non serve.
  if not exists (select 1 from public.push_subscriptions where user_id = auth.uid()) then
    delete from public.push_queue where user_id = auth.uid();
  end if;
end $$;

-- Sostituisce i promemoria programmati dell'utente. Gli allarmi urgenti
-- (urgente = true) si aggiungono e non vengono cancellati da una
-- sostituzione successiva: li toglie solo l'invio.
create or replace function public.sostituisci_promemoria(p_elementi jsonb)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'serve l''accesso';
  end if;
  if jsonb_typeof(p_elementi) <> 'array' or jsonb_array_length(p_elementi) > 120 then
    raise exception 'elenco non valido';
  end if;
  delete from public.push_queue where user_id = auth.uid() and not urgent;
  insert into public.push_queue (user_id, id, urgent, due_at, title, body)
  select auth.uid(), (e ->> 'id')::integer, coalesce((e ->> 'urgente')::boolean, false),
         (e ->> 'quando')::timestamptz, left(e ->> 'titolo', 200), left(e ->> 'testo', 1000)
  from jsonb_array_elements(p_elementi) e
  where (e ->> 'quando')::timestamptz < now() + interval '60 days'
  on conflict (user_id, id, urgent) do update
    set due_at = excluded.due_at, title = excluded.title, body = excluded.body;
end $$;

-- 3.3 Funzione per l'invio (solo ruolo di servizio) ----------------------------

-- Preleva (e toglie dalla coda) i promemoria scaduti, con le iscrizioni a cui
-- mandarli. Quelli scaduti da oltre 6 ore si scartano senza inviarli.
-- "skip locked": due invii contemporanei non mandano lo stesso promemoria.
create or replace function public.preleva_promemoria(p_limite integer default 500)
returns table (user_id uuid, id integer, title text, body text, urgent boolean,
               endpoint text, p256dh text, auth text)
language plpgsql security definer set search_path = '' as $$
begin
  delete from public.push_queue q where q.due_at < now() - interval '6 hours';
  return query
  with presi as (
    delete from public.push_queue q
    where (q.user_id, q.id, q.urgent) in (
      select x.user_id, x.id, x.urgent from public.push_queue x
      where x.due_at <= now()
      order by x.due_at
      limit p_limite
      for update skip locked
    )
    returning q.user_id, q.id, q.title, q.body, q.urgent
  )
  select p.user_id, p.id, p.title, p.body, p.urgent, s.endpoint, s.p256dh, s.auth
  from presi p
  join public.push_subscriptions s on s.user_id = p.user_id;
end $$;

-- Iscrizioni che il servizio push dice scadute (risposta 404/410).
create or replace function public.scarta_iscrizioni_push(p_endpoints text[])
returns void
language sql security definer set search_path = '' as $$
  delete from public.push_subscriptions where endpoint = any (p_endpoints);
$$;

revoke all on function public.registra_dispositivo_push(text, text, text) from public, anon;
revoke all on function public.rimuovi_dispositivo_push(text) from public, anon;
revoke all on function public.sostituisci_promemoria(jsonb) from public, anon;
revoke all on function public.preleva_promemoria(integer) from public, anon, authenticated;
revoke all on function public.scarta_iscrizioni_push(text[]) from public, anon, authenticated;
grant execute on function public.registra_dispositivo_push(text, text, text) to authenticated;
grant execute on function public.rimuovi_dispositivo_push(text) to authenticated;
grant execute on function public.sostituisci_promemoria(jsonb) to authenticated;
grant execute on function public.preleva_promemoria(integer) to service_role;
grant execute on function public.scarta_iscrizioni_push(text[]) to service_role;

commit;
