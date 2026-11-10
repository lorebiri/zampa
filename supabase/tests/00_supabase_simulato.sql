-- Ambiente Supabase minimo simulato, per provare lo schema su un Postgres
-- locale senza Docker e senza progetti cloud.
--
-- Riproduce soltanto ciò che lo schema di Zampa usa:
--   - i ruoli anon, authenticated, service_role (come in Supabase);
--   - lo schema auth con la tabella auth.users;
--   - auth.uid(), che come in Supabase legge l'utente dal setting di sessione
--     request.jwt.claim.sub (oppure da request.jwt.claims ->> 'sub');
--   - i privilegi predefiniti di Supabase: anon e authenticated ricevono
--     TUTTI i privilegi su tabelle e funzioni create in public (le protegge
--     solo RLS). È proprio la situazione da cui lo schema deve difendersi.
--
-- Da eseguire come superutente su un database vuoto.

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin noinherit bypassrls;
  end if;
end $$;

create schema if not exists auth;
grant usage on schema auth to anon, authenticated, service_role;

create table if not exists auth.users (
  id uuid primary key,
  email text
);

create or replace function auth.uid()
returns uuid language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;
grant execute on function auth.uid() to anon, authenticated, service_role;

grant usage on schema public to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on functions to anon, authenticated, service_role;
alter default privileges in schema public
  grant all on sequences to anon, authenticated, service_role;
