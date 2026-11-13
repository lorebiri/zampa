-- Test dei promemoria Web Push (sezione 3 di schema.sql). Da eseguire dopo
-- 00_supabase_simulato.sql e schema.sql: lo fa supabase/tests/esegui.sh.
-- Utenti: A e B con un browser ciascuno; anon senza accesso.

\set ON_ERROR_STOP 1
\set QUIET 1
set client_min_messages = warning;

drop schema if exists test cascade;
create schema test;
create table test.results (n serial, ok boolean, name text, detail text);
grant usage on schema test to anon, authenticated, service_role;
grant insert, select on test.results to anon, authenticated, service_role;
grant usage on sequence test.results_n_seq to anon, authenticated, service_role;
create function test.ok(cond boolean, name text, detail text default null)
returns void language plpgsql as $$
begin
  insert into test.results (ok, name, detail) values (coalesce(cond, false), name, detail);
end $$;
create function test.throws(sql text, name text, pattern text)
returns void language plpgsql as $$
begin
  begin
    execute sql;
  exception when others then
    perform test.ok(sqlerrm ilike '%' || pattern || '%', name, 'errore: ' || sqlerrm);
    return;
  end;
  perform test.ok(false, name, 'nessun errore');
end $$;

\set come_A 'reset role; select set_config(''request.jwt.claim.sub'', ''00000000-0000-0000-0000-00000000001a'', false); set role authenticated;'
\set come_B 'reset role; select set_config(''request.jwt.claim.sub'', ''00000000-0000-0000-0000-00000000001b'', false); set role authenticated;'
\set come_anon 'reset role; select set_config(''request.jwt.claim.sub'', '''', false); set role anon;'
\set come_servizio 'reset role; select set_config(''request.jwt.claim.sub'', '''', false); set role service_role;'
\set come_admin 'reset role; select set_config(''request.jwt.claim.sub'', '''', false);'

\o /dev/null
:come_admin
insert into auth.users (id) values
  ('00000000-0000-0000-0000-00000000001a'), ('00000000-0000-0000-0000-00000000001b')
on conflict do nothing;

-- Iscrizioni ------------------------------------------------------------------
:come_A
select public.registra_dispositivo_push('https://push.example/a1', 'chiaveA', 'authA');
select test.throws($$ select public.registra_dispositivo_push('http://insicuro/x', 'k', 'a') $$,
  'endpoint non https rifiutato', 'check');
:come_B
select public.registra_dispositivo_push('https://push.example/b1', 'chiaveB', 'authB');

:come_anon
select test.throws($$ select public.registra_dispositivo_push('https://push.example/z', 'k', 'a') $$,
  'anon non può registrare un dispositivo', 'permission denied');
select test.throws($$ select * from public.push_subscriptions $$,
  'anon non legge le iscrizioni', 'permission denied');

:come_A
select test.throws($$ select * from public.push_subscriptions $$,
  'un utente non legge le iscrizioni (neanche le sue)', 'permission denied');
select test.throws($$ select * from public.push_queue $$,
  'un utente non legge la coda', 'permission denied');
select test.throws($$ select * from public.preleva_promemoria(10) $$,
  'un utente non può prelevare i promemoria', 'permission denied');

-- Sostituzione ------------------------------------------------------------------
:come_A
select public.sostituisci_promemoria(jsonb_build_array(
  jsonb_build_object('id', 1, 'quando', now() - interval '1 minute', 'titolo', 'Pipì', 'testo', 'Portalo fuori'),
  jsonb_build_object('id', 2, 'quando', now() + interval '1 hour', 'titolo', 'Dose', 'testo', 'Fenobarbital'),
  jsonb_build_object('id', 3, 'quando', now() + interval '400 days', 'titolo', 'Lontano', 'testo', 'x'),
  jsonb_build_object('id', 90, 'quando', now(), 'titolo', 'SUBITO', 'testo', 'Allarme', 'urgente', true)
));
-- Una seconda sostituzione toglie i programmati ma non l'allarme urgente.
select public.sostituisci_promemoria(jsonb_build_array(
  jsonb_build_object('id', 1, 'quando', now() - interval '1 minute', 'titolo', 'Pipì', 'testo', 'Portalo fuori'),
  jsonb_build_object('id', 2, 'quando', now() + interval '1 hour', 'titolo', 'Dose', 'testo', 'Fenobarbital')
));
select test.throws($$ select public.sostituisci_promemoria('{"id":1}'::jsonb) $$,
  'elenco non valido rifiutato', 'elenco non valido');
:come_B
select public.sostituisci_promemoria(jsonb_build_array(
  jsonb_build_object('id', 1, 'quando', now() - interval '2 minutes', 'titolo', 'Di B', 'testo', 'b')
));
-- B non tocca i promemoria di A.
select public.sostituisci_promemoria('[]'::jsonb);

:come_admin
select test.ok((select count(*) from public.push_queue where user_id = '00000000-0000-0000-0000-00000000001a') = 3,
  'A: due programmati + un urgente (quello oltre 60 giorni scartato)');
select test.ok((select count(*) from public.push_queue where user_id = '00000000-0000-0000-0000-00000000001b') = 0,
  'B: la sostituzione vuota toglie solo i suoi');

-- Invio -------------------------------------------------------------------------
:come_admin
insert into public.push_queue (user_id, id, urgent, due_at, title, body) values
  ('00000000-0000-0000-0000-00000000001a', 7, false, now() - interval '7 hours', 'Vecchio', 'x');
:come_servizio
create temp table presi as select * from public.preleva_promemoria(100);
select test.ok((select count(*) from presi) = 2, 'prelevati solo gli scaduti: pipì e allarme',
  (select string_agg(title, ', ') from presi));
select test.ok((select bool_and(endpoint = 'https://push.example/a1') from presi),
  'inviati al browser di A');
select test.ok((select count(*) from public.preleva_promemoria(100)) = 0,
  'un secondo prelievo non li rimanda');
:come_admin
select test.ok(not exists (select 1 from public.push_queue where title = 'Vecchio'),
  'scaduti da oltre 6 ore: scartati');
select test.ok(exists (select 1 from public.push_queue where id = 2),
  'la dose futura resta in coda');

-- Iscrizioni scadute e rimozione ------------------------------------------------
:come_servizio
select public.scarta_iscrizioni_push(array['https://push.example/b1']);
:come_admin
select test.ok(not exists (select 1 from public.push_subscriptions where endpoint = 'https://push.example/b1'),
  'iscrizione scaduta tolta');
:come_B
select public.rimuovi_dispositivo_push('https://push.example/a1');
:come_admin
select test.ok(exists (select 1 from public.push_subscriptions where endpoint = 'https://push.example/a1'),
  'B non può togliere il browser di A');
:come_A
select public.rimuovi_dispositivo_push('https://push.example/a1');
:come_admin
select test.ok(not exists (select 1 from public.push_queue where user_id = '00000000-0000-0000-0000-00000000001a'),
  'senza dispositivi la coda di A si svuota');
delete from auth.users where id in ('00000000-0000-0000-0000-00000000001a', '00000000-0000-0000-0000-00000000001b');

-- Riepilogo ---------------------------------------------------------------------
:come_admin
\o
\pset format unaligned
\pset tuples_only on
select case when ok then 'ok ' else 'not ok ' end || n || ' - ' || name
       || case when not ok then '  # ' || coalesce(detail, '') else '' end
from test.results order by n;
select format('# %s test, %s superati, %s falliti', count(*), count(*) filter (where ok), count(*) filter (where not ok))
from test.results;
do $$
begin
  if exists (select 1 from test.results where not ok) then
    raise exception 'Alcuni test sono falliti';
  end if;
end $$;
