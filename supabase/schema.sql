-- Zampa: schema del database Supabase (Postgres), regione UE.
-- Da eseguire nel SQL Editor del progetto Supabase. È rieseguibile: si può
-- lanciare più volte, anche su un database che ha già la versione precedente
-- (in quel caso basta anche supabase/migrations/2026-11-10_sicurezza.sql).
--
-- Modello: ogni cane appartiene a uno o più membri (famiglia). Tutti i dati
-- (diario, cartella, pesi, dosi, riproduzione, scale, esami) sono righe di
-- "entries" collegate al cane. Le regole di sicurezza per riga (RLS) fanno sì
-- che ogni utente veda e modifichi SOLO i cani di cui è membro.
--
-- Provato in locale con supabase/tests/esegui.sh (vedi supabase/tests/).

begin;

-- ===========================================================================
-- 1. Tabelle (versione 1)
-- ===========================================================================

create table if not exists public.dogs (
  id text primary key,
  owner uuid not null references auth.users (id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  deleted boolean not null default false
);

create table if not exists public.dog_members (
  dog_id text not null references public.dogs (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'famiglia' check (role in ('proprietario', 'famiglia')),
  created_at timestamptz not null default now(),
  primary key (dog_id, user_id)
);

create table if not exists public.entries (
  id text primary key,
  dog_id text not null references public.dogs (id) on delete cascade,
  kind text not null check (kind in ('log', 'record', 'weight', 'dose', 'repro', 'qol', 'lab')),
  data jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null,
  deleted boolean not null default false
);
create index if not exists entries_dog_updated on public.entries (dog_id, updated_at);
create index if not exists dogs_updated on public.dogs (updated_at);

create table if not exists public.invites (
  code text primary key,
  dog_id text not null references public.dogs (id) on delete cascade,
  created_by uuid not null references auth.users (id) on delete cascade,
  expires_at timestamptz not null default now() + interval '7 days'
);

-- ===========================================================================
-- 2. Sicurezza (2026-11-10). Questa sezione coincide con
--    supabase/migrations/2026-11-10_sicurezza.sql.
-- ===========================================================================

-- 2.1 Colonne e tabelle nuove -------------------------------------------------

-- Inviti monouso: ogni codice vale per un numero massimo di usi (di norma 1).
alter table public.invites add column if not exists created_at timestamptz not null default now();
alter table public.invites add column if not exists max_uses integer not null default 1;
alter table public.invites add column if not exists uses integer not null default 0;
alter table public.invites add column if not exists used_by uuid references auth.users (id) on delete set null;
alter table public.invites add column if not exists used_at timestamptz;

-- Tentativi di accept_invite, per limitare chi prova codici a caso.
create table if not exists public.invite_attempts (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  at timestamptz not null default now(),
  ok boolean not null
);

create index if not exists invite_attempts_user_at on public.invite_attempts (user_id, at);
create index if not exists invites_dog on public.invites (dog_id);
create index if not exists dog_members_user on public.dog_members (user_id);
create index if not exists entries_updated on public.entries (updated_at);

-- 2.2 Vincoli sui dati ---------------------------------------------------------
-- I vincoli "not valid" non ricontrollano le righe già presenti, ma valgono
-- per ogni riga nuova o modificata.

-- "data" deve essere un oggetto JSON: un array o un numero farebbe fallire la
-- sincronizzazione sui telefoni degli altri familiari.
alter table public.dogs drop constraint if exists dogs_data_object;
alter table public.dogs add constraint dogs_data_object
  check (jsonb_typeof(data) = 'object') not valid;
alter table public.entries drop constraint if exists entries_data_object;
alter table public.entries add constraint entries_data_object
  check (jsonb_typeof(data) = 'object') not valid;

-- L'id dentro "data" deve coincidere con quello della riga: l'app applica i
-- dati ricevuti usando gli id contenuti in "data", quindi una voce con
-- dogId diverso finirebbe nel cane sbagliato sul telefono di un familiare.
alter table public.dogs drop constraint if exists dogs_data_id;
alter table public.dogs add constraint dogs_data_id
  check (deleted or coalesce(data ->> 'id' = id, false)) not valid;
alter table public.entries drop constraint if exists entries_data_ids;
alter table public.entries add constraint entries_data_ids
  check (deleted or coalesce(data ->> 'id' = id and data ->> 'dogId' = dog_id, false)) not valid;

-- Limite di dimensione (256 KiB per riga): le foto non vengono sincronizzate,
-- quindi nessuna voce reale si avvicina a questo limite.
alter table public.dogs drop constraint if exists dogs_data_size;
alter table public.dogs add constraint dogs_data_size
  check (octet_length(data::text) <= 262144) not valid;
alter table public.entries drop constraint if exists entries_data_size;
alter table public.entries add constraint entries_data_size
  check (octet_length(data::text) <= 262144) not valid;

-- Codici d'invito: 8-32 caratteri dell'alfabeto dell'app (senza 0/O e 1/I).
alter table public.invites drop constraint if exists invites_code_format;
alter table public.invites add constraint invites_code_format
  check (code ~ '^[A-HJ-NP-Z2-9]{8,32}$') not valid;
alter table public.invites drop constraint if exists invites_uses_range;
alter table public.invites add constraint invites_uses_range
  check (max_uses between 1 and 10 and uses between 0 and max_uses);

-- 2.3 Funzioni di appoggio per le regole (security definer) ------------------
-- Tutte le funzioni security definer hanno search_path vuoto e nomi completi
-- (schema.oggetto): nessuno può dirottarle creando oggetti con lo stesso nome.

create or replace function public.is_member(d text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.dog_members m
    where m.dog_id = d and m.user_id = (select auth.uid())
  );
$$;

create or replace function public.is_owner(d text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.dogs g
    where g.id = d and g.owner = (select auth.uid())
  );
$$;

-- Proprietario attuale (già salvato) di un cane: serve al "with check" di
-- dogs_update per vietare il cambio di proprietario.
create or replace function public.dog_owner(d text)
returns uuid language sql stable security definer set search_path = '' as $$
  select g.owner from public.dogs g where g.id = d;
$$;

-- 2.4 Trigger -------------------------------------------------------------------

-- L'orario di ogni modifica lo assegna il server: la sincronizzazione non
-- dipende dagli orologi dei telefoni.
create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;
drop trigger if exists dogs_touch on public.dogs;
create trigger dogs_touch before insert or update on public.dogs
for each row execute function public.touch_updated_at();
drop trigger if exists entries_touch on public.entries;
create trigger entries_touch before insert or update on public.entries
for each row execute function public.touch_updated_at();

-- Cani: id e proprietario non si cambiano. Se un familiare (non il
-- proprietario) "elimina" il cane, in realtà smette di condividerlo: il cane
-- resta intatto per il proprietario e gli altri familiari.
create or replace function public.guard_dog_update()
returns trigger language plpgsql set search_path = '' as $$
declare uid uuid := (select auth.uid());
begin
  if new.id is distinct from old.id then
    raise exception 'Non si può cambiare l''identificativo di un cane'
      using errcode = '42501';
  end if;
  -- Il passaggio di proprietà resta possibile solo all'amministratore
  -- (SQL Editor o chiave service_role, dove auth.uid() è vuoto).
  if new.owner is distinct from old.owner and uid is not null then
    raise exception 'Solo l''amministratore può cambiare il proprietario di un cane'
      using errcode = '42501';
  end if;
  if new.deleted and not old.deleted and uid is not null and uid <> old.owner then
    delete from public.dog_members where dog_id = old.id and user_id = uid;
    return null; -- nessuna modifica al cane
  end if;
  return new;
end $$;
drop trigger if exists dogs_guard on public.dogs;
create trigger dogs_guard before update on public.dogs
for each row execute function public.guard_dog_update();

-- Voci: cane, tipo e id non si cambiano; l'autore lo scrive il server.
create or replace function public.guard_entry()
returns trigger language plpgsql set search_path = '' as $$
declare uid uuid := (select auth.uid());
begin
  if tg_op = 'UPDATE' then
    if new.id is distinct from old.id
       or new.dog_id is distinct from old.dog_id
       or new.kind is distinct from old.kind then
      raise exception 'Non si può spostare una voce su un altro cane o tipo'
        using errcode = '42501';
    end if;
  end if;
  -- pg_trigger_depth() = 1: solo per le scritture dirette, non per l'"on
  -- delete set null" che parte quando un utente elimina l'account (lì auth.uid()
  -- è ancora l'utente eliminato e lo rimetterebbe come autore).
  if uid is not null and pg_trigger_depth() = 1 then
    new.updated_by := uid;
  end if;
  return new;
end $$;
drop trigger if exists entries_guard on public.entries;
create trigger entries_guard before insert or update on public.entries
for each row execute function public.guard_entry();

-- Lapidi: una riga eliminata non conserva i dati (minimizzazione GDPR).
create or replace function public.minimize_tombstone()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.deleted then
    new.data := '{}'::jsonb;
  end if;
  return new;
end $$;
drop trigger if exists dogs_tombstone on public.dogs;
create trigger dogs_tombstone before insert or update on public.dogs
for each row execute function public.minimize_tombstone();
drop trigger if exists entries_tombstone on public.entries;
create trigger entries_tombstone before insert or update on public.entries
for each row execute function public.minimize_tombstone();

-- Il creatore di un cane ne diventa automaticamente proprietario.
create or replace function public.add_owner_membership()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.dog_members (dog_id, user_id, role)
  values (new.id, new.owner, 'proprietario')
  on conflict do nothing;
  return new;
end $$;
drop trigger if exists dogs_owner_membership on public.dogs;
create trigger dogs_owner_membership after insert on public.dogs
for each row execute function public.add_owner_membership();

-- Inviti creati dall'app: scadenza e usi li decide il server (il telefono non
-- può creare un codice che dura per sempre o vale per cento persone).
-- Al massimo 10 inviti attivi per cane.
create or replace function public.guard_invite()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if (select auth.uid()) is not null then
    new.created_by := (select auth.uid());
    new.created_at := now();
    new.expires_at := now() + interval '7 days';
    new.max_uses := 1;
    new.uses := 0;
    new.used_by := null;
    new.used_at := null;
  end if;
  new.code := upper(new.code);
  if (select count(*) from public.invites i
      where i.dog_id = new.dog_id and i.expires_at > now() and i.uses < i.max_uses) >= 10 then
    raise exception 'Troppi inviti attivi per questo cane' using errcode = 'P0001';
  end if;
  return new;
end $$;
drop trigger if exists invites_guard on public.invites;
create trigger invites_guard before insert on public.invites
for each row execute function public.guard_invite();

-- 2.5 Regole per riga (RLS) ----------------------------------------------------

alter table public.dogs enable row level security;
alter table public.dog_members enable row level security;
alter table public.entries enable row level security;
alter table public.invites enable row level security;
alter table public.invite_attempts enable row level security;

drop policy if exists dogs_select on public.dogs;
create policy dogs_select on public.dogs for select to authenticated
  using (public.is_member(id));
drop policy if exists dogs_insert on public.dogs;
create policy dogs_insert on public.dogs for insert to authenticated
  with check (owner = (select auth.uid()));
drop policy if exists dogs_update on public.dogs;
create policy dogs_update on public.dogs for update to authenticated
  using (public.is_member(id))
  with check (public.is_member(id) and owner = public.dog_owner(id));
-- Nessuna regola di delete: i cani si eliminano con le lapidi (deleted).

drop policy if exists members_select on public.dog_members;
create policy members_select on public.dog_members for select to authenticated
  using (public.is_member(dog_id));
drop policy if exists members_delete on public.dog_members;
-- Un familiare può uscire da un cane condiviso; il proprietario può togliere
-- gli altri membri, ma non sé stesso (il cane resterebbe senza nessuno).
create policy members_delete on public.dog_members for delete to authenticated using (
  (user_id = (select auth.uid()) and role <> 'proprietario')
  or (user_id <> (select auth.uid()) and public.is_owner(dog_id))
);
-- Nessuna regola di insert/update: si entra solo con accept_invite o creando
-- un cane.

drop policy if exists entries_select on public.entries;
create policy entries_select on public.entries for select to authenticated
  using (public.is_member(dog_id));
drop policy if exists entries_insert on public.entries;
create policy entries_insert on public.entries for insert to authenticated
  with check (public.is_member(dog_id));
drop policy if exists entries_update on public.entries;
create policy entries_update on public.entries for update to authenticated
  using (public.is_member(dog_id))
  with check (public.is_member(dog_id));

drop policy if exists invites_select on public.invites;
create policy invites_select on public.invites for select to authenticated
  using (created_by = (select auth.uid()));
drop policy if exists invites_insert on public.invites;
create policy invites_insert on public.invites for insert to authenticated
  with check (created_by = (select auth.uid()) and public.is_member(dog_id));
drop policy if exists invites_delete on public.invites;
create policy invites_delete on public.invites for delete to authenticated
  using (created_by = (select auth.uid()) or public.is_owner(dog_id));
-- invite_attempts: nessuna regola, la legge e scrive solo accept_invite.

-- 2.6 Funzioni chiamabili dall'app (RPC) -----------------------------------------

-- Accettare un invito: aggiunge l'utente come membro del cane e consuma il
-- codice. Al massimo 5 tentativi falliti all'ora per utente.
-- Un codice non valido, scaduto o già usato restituisce NULL (non un errore):
-- così il tentativo fallito resta registrato (un errore annullerebbe anche la
-- registrazione). Il superamento del limite invece è un errore.
create or replace function public.accept_invite(invite_code text)
returns text language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
  inv public.invites%rowtype;
  failures integer;
begin
  if uid is null then
    raise exception 'Accesso richiesto' using errcode = '42501';
  end if;

  delete from public.invite_attempts a
  where a.user_id = uid and a.at < now() - interval '1 day';
  select count(*) into failures from public.invite_attempts a
  where a.user_id = uid and not a.ok and a.at > now() - interval '1 hour';
  if failures >= 5 then
    raise exception 'Troppi tentativi con codici non validi: riprova tra un''ora'
      using errcode = 'P0001';
  end if;

  select * into inv from public.invites i
  where i.code = upper(btrim(coalesce(invite_code, '')))
  for update;

  -- Già membro (es. il codice ripetuto due volte): non consuma il codice.
  if found and exists (select 1 from public.dog_members m
                       where m.dog_id = inv.dog_id and m.user_id = uid) then
    return inv.dog_id;
  end if;

  if not found
     or inv.expires_at <= now()
     or inv.uses >= inv.max_uses
     or not exists (select 1 from public.dogs g where g.id = inv.dog_id and not g.deleted) then
    insert into public.invite_attempts (user_id, ok) values (uid, false);
    return null;
  end if;

  insert into public.dog_members (dog_id, user_id, role)
  values (inv.dog_id, uid, 'famiglia');
  update public.invites
  set uses = uses + 1, used_by = uid, used_at = now()
  where code = inv.code;
  insert into public.invite_attempts (user_id, ok) values (uid, true);
  return inv.dog_id;
end $$;

-- Creare un invito con il codice generato dal server (alternativa consigliata
-- all'insert diretto dall'app). 8 caratteri da 32 simboli = 40 bit casuali.
create or replace function public.create_invite(p_dog_id text)
returns text language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := (select auth.uid());
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  b bytea;
  c text;
  pos integer[] := array[0, 1, 2, 3, 4, 5, 9, 10]; -- byte del UUID v4 senza bit fissi
  i integer;
begin
  if uid is null then
    raise exception 'Accesso richiesto' using errcode = '42501';
  end if;
  if not exists (select 1 from public.dog_members m
                 where m.dog_id = p_dog_id and m.user_id = uid) then
    raise exception 'Non sei membro di questo cane' using errcode = '42501';
  end if;
  for attempt in 1 .. 5 loop
    b := uuid_send(gen_random_uuid());
    c := '';
    foreach i in array pos loop
      c := c || substr(alphabet, (get_byte(b, i) % 32) + 1, 1);
    end loop;
    begin
      insert into public.invites (code, dog_id, created_by)
      values (c, p_dog_id, uid);
      return c;
    exception when unique_violation then
      -- codice già esistente: si riprova
    end;
  end loop;
  raise exception 'Impossibile generare un codice, riprova';
end $$;

-- Eliminazione dell'account dall'app (richiesta da Apple, diritto all'oblio
-- GDPR): cancella l'utente; i cani di cui era proprietario e tutti i loro dati
-- vengono eliminati a cascata; dai cani condivisi esce come membro (le voci
-- che aveva scritto lì restano al proprietario, senza autore).
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = '' as $$
declare uid uuid := (select auth.uid());
begin
  if uid is null then
    raise exception 'Accesso richiesto' using errcode = '42501';
  end if;
  delete from auth.users where id = uid;
end $$;

-- 2.7 Permessi ------------------------------------------------------------------
-- Supabase concede di default TUTTO su public ad anon e authenticated (anche
-- TRUNCATE, che ignora RLS) e l'esecuzione di ogni funzione a PUBLIC.
-- Qui si concede solo il necessario.

revoke all on public.dogs, public.dog_members, public.entries, public.invites,
  public.invite_attempts from public, anon, authenticated;

grant select, insert on public.dogs to authenticated;
grant update (data, updated_at, deleted) on public.dogs to authenticated;
grant select, delete on public.dog_members to authenticated;
-- upsert di PostgREST = insert ... on conflict do update su tutte le colonne
-- inviate: servono i permessi su tutte; i trigger impediscono gli spostamenti.
grant select, insert, update on public.entries to authenticated;
grant select, insert, delete on public.invites to authenticated;

revoke all on function public.is_member(text) from public, anon;
revoke all on function public.is_owner(text) from public, anon;
revoke all on function public.dog_owner(text) from public, anon;
grant execute on function public.is_member(text) to authenticated;
grant execute on function public.is_owner(text) to authenticated;
grant execute on function public.dog_owner(text) to authenticated;

revoke all on function public.touch_updated_at() from public, anon, authenticated;
revoke all on function public.guard_dog_update() from public, anon, authenticated;
revoke all on function public.guard_entry() from public, anon, authenticated;
revoke all on function public.minimize_tombstone() from public, anon, authenticated;
revoke all on function public.add_owner_membership() from public, anon, authenticated;
revoke all on function public.guard_invite() from public, anon, authenticated;

revoke all on function public.accept_invite(text) from public, anon;
revoke all on function public.create_invite(text) from public, anon;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.accept_invite(text) to authenticated;
grant execute on function public.create_invite(text) to authenticated;
grant execute on function public.delete_my_account() to authenticated;

commit;

-- ===========================================================================
-- 3. Promemoria Web Push (2026-11-14). Questa sezione coincide con
--    supabase/migrations/2026-11-14_promemoria_web.sql.
-- ===========================================================================

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
