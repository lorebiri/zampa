-- Zampa: schema del database Supabase (Postgres), regione UE.
-- Da eseguire una volta nel SQL Editor del progetto Supabase.
--
-- Modello: ogni cane appartiene a uno o più membri (famiglia). Tutti i dati
-- (diario, cartella, pesi, dosi, riproduzione, scale, esami) sono righe di
-- "entries" collegate al cane. Le regole di sicurezza per riga (RLS) fanno sì
-- che ogni utente veda e modifichi SOLO i cani di cui è membro.

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

-- L'orario di ogni modifica lo assegna il server: la sincronizzazione non
-- dipende dagli orologi dei telefoni.
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
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

-- Appartenenza (security definer per evitare ricorsione nelle policy).
create or replace function public.is_member(d text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from dog_members where dog_id = d and user_id = auth.uid());
$$;

-- Il creatore di un cane ne diventa automaticamente proprietario.
create or replace function public.add_owner_membership()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into dog_members (dog_id, user_id, role)
  values (new.id, new.owner, 'proprietario')
  on conflict do nothing;
  return new;
end $$;
drop trigger if exists dogs_owner_membership on public.dogs;
create trigger dogs_owner_membership after insert on public.dogs
for each row execute function public.add_owner_membership();

alter table public.dogs enable row level security;
alter table public.dog_members enable row level security;
alter table public.entries enable row level security;
alter table public.invites enable row level security;

drop policy if exists dogs_select on public.dogs;
create policy dogs_select on public.dogs for select using (public.is_member(id));
drop policy if exists dogs_insert on public.dogs;
create policy dogs_insert on public.dogs for insert with check (owner = auth.uid());
drop policy if exists dogs_update on public.dogs;
create policy dogs_update on public.dogs for update using (public.is_member(id));

drop policy if exists members_select on public.dog_members;
create policy members_select on public.dog_members for select using (public.is_member(dog_id));
drop policy if exists members_delete on public.dog_members;
-- Ognuno può uscire da un cane condiviso; il proprietario può togliere i membri.
create policy members_delete on public.dog_members for delete using (
  user_id = auth.uid()
  or exists (select 1 from public.dogs d where d.id = dog_id and d.owner = auth.uid())
);

drop policy if exists entries_select on public.entries;
create policy entries_select on public.entries for select using (public.is_member(dog_id));
drop policy if exists entries_insert on public.entries;
create policy entries_insert on public.entries for insert with check (public.is_member(dog_id));
drop policy if exists entries_update on public.entries;
create policy entries_update on public.entries for update using (public.is_member(dog_id));

drop policy if exists invites_select on public.invites;
create policy invites_select on public.invites for select using (created_by = auth.uid());
drop policy if exists invites_insert on public.invites;
create policy invites_insert on public.invites for insert
  with check (created_by = auth.uid() and public.is_member(dog_id));

-- Accettare un invito: aggiunge l'utente come membro del cane.
create or replace function public.accept_invite(invite_code text)
returns text language plpgsql security definer set search_path = public as $$
declare d text;
begin
  select dog_id into d from invites
  where code = upper(invite_code) and expires_at > now();
  if d is null then
    raise exception 'Codice non valido o scaduto';
  end if;
  insert into dog_members (dog_id, user_id, role)
  values (d, auth.uid(), 'famiglia') on conflict do nothing;
  return d;
end $$;

-- Eliminazione dell'account dall'app (richiesta da Apple, diritto all'oblio
-- GDPR): cancella l'utente; i cani di cui era proprietario e tutti i loro dati
-- vengono eliminati a cascata; dai cani condivisi esce come membro.
create or replace function public.delete_my_account()
returns void language plpgsql security definer set search_path = public, auth as $$
begin
  delete from auth.users where id = auth.uid();
end $$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
grant execute on function public.accept_invite(text) to authenticated;
