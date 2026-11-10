-- Test di sicurezza dello schema di Zampa (RLS, inviti, funzioni, permessi).
-- Da eseguire dopo 00_supabase_simulato.sql e schema.sql, su un database
-- vuoto: lo fa supabase/tests/esegui.sh. Stile TAP: ogni riga "ok"/"not ok";
-- alla fine il riepilogo, e l'uscita con errore se qualcosa fallisce.
--
-- Utenti: A proprietario di Rex; B familiare; C estraneo; D secondo
-- familiare; E chi prova codici a caso; F utente che elimina l'account.

\set ON_ERROR_STOP 1
\set QUIET 1
set client_min_messages = warning;

-- ---------------------------------------------------------------------------
-- Strumenti di test
-- ---------------------------------------------------------------------------
drop schema if exists test cascade;
create schema test;
create table test.results (n serial, ok boolean, name text, detail text);
grant usage on schema test to anon, authenticated;
grant insert, select on test.results to anon, authenticated;
grant usage on sequence test.results_n_seq to anon, authenticated;

create function test.ok(cond boolean, name text, detail text default null)
returns void language plpgsql as $$
begin
  insert into test.results (ok, name, detail) values (coalesce(cond, false), name, detail);
end $$;

-- Vero se l'istruzione fallisce con un errore che contiene "pattern".
create function test.raises(sql text, pattern text)
returns boolean language plpgsql as $$
begin
  begin
    execute sql;
  exception when others then
    return sqlerrm ilike '%' || pattern || '%';
  end;
  return false;
end $$;

-- L'istruzione deve fallire con un errore che contiene "pattern".
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

-- Esegue un'istruzione e restituisce il numero di righe toccate.
create function test.rows(sql text)
returns integer language plpgsql as $$
declare n integer;
begin
  execute sql;
  get diagnostics n = row_count;
  return n;
end $$;
grant execute on all functions in schema test to anon, authenticated;

-- Cambio di utente (come farebbe PostgREST con il JWT).
\set come_A 'reset role; select set_config(''request.jwt.claim.sub'', ''00000000-0000-0000-0000-00000000000a'', false); set role authenticated;'
\set come_B 'reset role; select set_config(''request.jwt.claim.sub'', ''00000000-0000-0000-0000-00000000000b'', false); set role authenticated;'
\set come_C 'reset role; select set_config(''request.jwt.claim.sub'', ''00000000-0000-0000-0000-00000000000c'', false); set role authenticated;'
\set come_D 'reset role; select set_config(''request.jwt.claim.sub'', ''00000000-0000-0000-0000-00000000000d'', false); set role authenticated;'
\set come_E 'reset role; select set_config(''request.jwt.claim.sub'', ''00000000-0000-0000-0000-00000000000e'', false); set role authenticated;'
\set come_F 'reset role; select set_config(''request.jwt.claim.sub'', ''00000000-0000-0000-0000-00000000000f'', false); set role authenticated;'
\set come_anon 'reset role; select set_config(''request.jwt.claim.sub'', '''', false); set role anon;'
\set come_admin 'reset role; select set_config(''request.jwt.claim.sub'', '''', false);'
\o /dev/null

:come_admin
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'a@prova.it'),
  ('00000000-0000-0000-0000-00000000000b', 'b@prova.it'),
  ('00000000-0000-0000-0000-00000000000c', 'c@prova.it'),
  ('00000000-0000-0000-0000-00000000000d', 'd@prova.it'),
  ('00000000-0000-0000-0000-00000000000e', 'e@prova.it'),
  ('00000000-0000-0000-0000-00000000000f', 'f@prova.it');

-- ---------------------------------------------------------------------------
-- 1. Creazione di un cane, orario e autore assegnati dal server
-- ---------------------------------------------------------------------------
:come_A
insert into public.dogs (id, owner, data)
values ('rex', auth.uid(), '{"id":"rex","name":"Rex"}');
select test.ok((select role from public.dog_members where dog_id = 'rex' and user_id = auth.uid()) = 'proprietario',
  'chi crea un cane ne diventa proprietario');
select test.throws($$insert into public.dogs (id, owner, data)
  values ('finto', '00000000-0000-0000-0000-00000000000b', '{"id":"finto"}')$$,
  'non si crea un cane intestato a un altro', 'row-level security');

insert into public.entries (id, dog_id, kind, data, updated_at, updated_by)
values ('e1', 'rex', 'log', '{"id":"e1","dogId":"rex","t":"pipi"}', '2000-01-01', '00000000-0000-0000-0000-00000000000c');
select test.ok((select updated_at > now() - interval '1 minute' from public.entries where id = 'e1'),
  'updated_at assegnato dal server all''inserimento (ignora l''orario del telefono)');
select test.ok((select updated_by = auth.uid() from public.entries where id = 'e1'),
  'updated_by assegnato dal server (non si firma a nome di altri)');
update public.entries set updated_at = '2100-01-01', data = '{"id":"e1","dogId":"rex","t":"cacca"}' where id = 'e1';
select test.ok((select updated_at <= now() from public.entries where id = 'e1'),
  'updated_at assegnato dal server alla modifica (niente date nel futuro)');
update public.dogs set updated_at = '2000-01-01' where id = 'rex';
select test.ok((select updated_at > now() - interval '1 minute' from public.dogs where id = 'rex'),
  'updated_at del cane assegnato dal server');

-- ---------------------------------------------------------------------------
-- 2. Un estraneo non legge né scrive
-- ---------------------------------------------------------------------------
:come_C
select test.ok((select count(*) from public.dogs) = 0, 'estraneo: non vede i cani altrui');
select test.ok((select count(*) from public.entries) = 0, 'estraneo: non vede le voci altrui');
select test.ok((select count(*) from public.dog_members) = 0, 'estraneo: non vede i membri altrui');
select test.ok((select count(*) from public.invites) = 0, 'estraneo: non vede gli inviti altrui');
select test.ok(test.rows($$update public.dogs set data = '{"id":"rex","name":"Pippo"}' where id = 'rex'$$) = 0,
  'estraneo: non modifica il cane altrui');
select test.ok(test.rows($$update public.entries set deleted = true where id = 'e1'$$) = 0,
  'estraneo: non cancella (lapide) le voci altrui');
select test.throws($$insert into public.entries (id, dog_id, kind, data)
  values ('x1', 'rex', 'log', '{"id":"x1","dogId":"rex"}')$$,
  'estraneo: non aggiunge voci al cane altrui', 'row-level security');
select test.throws($$insert into public.entries (id, dog_id, kind, data)
  values ('e1', 'rex', 'log', '{"id":"e1","dogId":"rex"}')
  on conflict (id) do update set data = excluded.data$$,
  'estraneo: l''upsert su una voce altrui è rifiutato', 'row-level security');
select test.throws($$insert into public.invites (code, dog_id, created_by)
  values ('CCCCCCCC', 'rex', auth.uid())$$,
  'estraneo: non crea inviti per il cane altrui', 'row-level security');
select test.throws($$select public.create_invite('rex')$$,
  'estraneo: create_invite rifiutato', 'non sei membro');
select test.ok(test.rows($$delete from public.dog_members where dog_id = 'rex'$$) = 0,
  'estraneo: non toglie membri');
select test.throws($$delete from public.dogs where id = 'rex'$$,
  'estraneo: niente delete diretto sui cani', 'permission denied');
:come_A
select test.ok((select data ->> 'name' from public.dogs where id = 'rex') = 'Rex'
  and (select count(*) from public.dog_members where dog_id = 'rex') = 1
  and (select not deleted from public.entries where id = 'e1'),
  'dopo i tentativi dell''estraneo i dati di Rex sono intatti');

-- ---------------------------------------------------------------------------
-- 3. Ruolo anon (non autenticato) e permessi pericolosi
-- ---------------------------------------------------------------------------
:come_anon
select test.throws($$select count(*) from public.dogs$$, 'anon: niente accesso ai cani', 'permission denied');
select test.throws($$select count(*) from public.entries$$, 'anon: niente accesso alle voci', 'permission denied');
select test.throws($$select public.accept_invite('AAAAAAAA')$$, 'anon: accept_invite vietato', 'permission denied');
select test.throws($$select public.delete_my_account()$$, 'anon: delete_my_account vietato', 'permission denied');
select test.throws($$select public.is_member('rex')$$, 'anon: is_member vietato', 'permission denied');
:come_C
select test.throws($$truncate public.entries$$, 'authenticated: TRUNCATE (che ignora RLS) vietato', 'permission denied');
select test.throws($$select * from public.invite_attempts$$, 'authenticated: tabella dei tentativi inaccessibile', 'permission denied');

-- ---------------------------------------------------------------------------
-- 4. Inviti: scadenza imposta dal server, monouso
-- ---------------------------------------------------------------------------
:come_A
insert into public.invites (code, dog_id, created_by, expires_at, max_uses)
values ('ABCDEFGH', 'rex', auth.uid(), '2100-01-01', 10);
select test.ok((select expires_at <= now() + interval '7 days' and max_uses = 1 and uses = 0
  from public.invites where code = 'ABCDEFGH'),
  'invito: scadenza (7 giorni) e usi (1) decisi dal server, non dal telefono');
select test.throws($$insert into public.invites (code, dog_id, created_by) values ('abc', 'rex', auth.uid())$$,
  'invito: codice troppo corto o fuori alfabeto rifiutato', 'invites_code_format');
:come_B
select test.ok((select count(*) from public.invites) = 0, 'familiare/altri: non vedono gli inviti di A');
select test.ok(public.accept_invite(' abcdefgh ') = 'rex', 'invito valido accettato (spazi e minuscole ammessi)');
select test.ok((select count(*) from public.dogs where id = 'rex') = 1, 'il nuovo familiare vede il cane');
select test.ok((select count(*) from public.entries where dog_id = 'rex') = 1, 'il nuovo familiare vede le voci');
select test.ok(public.accept_invite('ABCDEFGH') = 'rex', 'chi è già membro può ripetere il codice senza errori');
:come_D
select test.ok(public.accept_invite('ABCDEFGH') is null, 'invito consumato: un secondo utente è rifiutato');
select test.ok((select count(*) from public.dogs where id = 'rex') = 0, 'il secondo utente non è diventato membro');
:come_A
select test.ok((select uses = 1 and used_by = '00000000-0000-0000-0000-00000000000b'
  from public.invites where code = 'ABCDEFGH'), 'l''invito registra chi l''ha usato');

-- Invito scaduto (inserito direttamente dall'amministratore).
:come_admin
insert into public.invites (code, dog_id, created_by, expires_at)
values ('SCADENZA', 'rex', '00000000-0000-0000-0000-00000000000a', now() - interval '1 minute');
:come_E
select test.ok(public.accept_invite('SCADENZA') is null, 'invito scaduto rifiutato');
select test.ok((select count(*) from public.dogs where id = 'rex') = 0, 'con l''invito scaduto non si entra');

-- ---------------------------------------------------------------------------
-- 5. Limite ai tentativi di accept_invite
-- ---------------------------------------------------------------------------
-- E ha già 1 tentativo fallito (codice scaduto); altri 4 arrivano al limite.
select public.accept_invite('ZZZZZZZ2');
select public.accept_invite('ZZZZZZZ3');
select public.accept_invite('ZZZZZZZ4');
select public.accept_invite('ZZZZZZZ5');
:come_A
insert into public.invites (code, dog_id, created_by) values ('VALEVA23', 'rex', auth.uid());
:come_E
select test.throws($$select public.accept_invite('ZZZZZZZ6')$$,
  'dopo 5 tentativi falliti in un''ora: bloccato', 'troppi tentativi');
select test.throws($$select public.accept_invite('VALEVA23')$$,
  'durante il blocco anche un codice valido è rifiutato', 'troppi tentativi');
:come_admin
update public.invite_attempts set at = at - interval '2 hours'
where user_id = '00000000-0000-0000-0000-00000000000e';
:come_E
select test.ok(public.accept_invite('VALEVA23') = 'rex', 'dopo un''ora si può riprovare');
select test.ok((select count(*) from public.dog_members where dog_id = 'rex' and user_id = auth.uid()) = 1,
  'E ora è membro di Rex');
select test.ok(test.rows($$delete from public.dog_members where dog_id = 'rex' and user_id = auth.uid()$$) = 1,
  'un familiare può uscire da un cane condiviso');

-- ---------------------------------------------------------------------------
-- 6. Il familiare non può cambiare proprietario né eliminare il cane altrui
-- ---------------------------------------------------------------------------
:come_B
select test.throws($$update public.dogs set owner = auth.uid() where id = 'rex'$$,
  'familiare: non si intesta il cane (permesso di colonna)', 'permission denied');
select test.throws($$update public.dogs set id = 'rex2' where id = 'rex'$$,
  'familiare: non cambia l''id del cane', 'permission denied');
select test.ok(test.rows($$update public.dogs set data = '{"id":"rex","name":"Rex","peso":30}' where id = 'rex'$$) = 1,
  'familiare: può aggiornare i dati del cane');
-- Seconda difesa: il trigger, anche per chi avesse il permesso di colonna.
:come_admin
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000b', false);
select test.throws($$update public.dogs set owner = '00000000-0000-0000-0000-00000000000b' where id = 'rex'$$,
  'trigger: il proprietario non cambia nemmeno con privilegi di tabella', 'proprietario');
-- Terza difesa: il "with check" della regola dogs_update, provato da solo.
begin;
alter table public.dogs disable trigger dogs_guard;
grant update (owner) on public.dogs to authenticated;
set local role authenticated;
select test.raises($$update public.dogs set owner = '00000000-0000-0000-0000-00000000000b' where id = 'rex'$$,
  'row-level security') as policy_ok \gset
rollback;
select test.ok(:'policy_ok'::boolean,
  'policy: dogs_update ha un with check che vieta il cambio di proprietario');
:come_A
select test.ok((select owner = '00000000-0000-0000-0000-00000000000a' from public.dogs where id = 'rex'),
  'Rex è ancora di A');

-- Un familiare che "elimina" il cane in realtà smette di condividerlo.
:come_B
select test.ok(test.rows($$update public.dogs set deleted = true where id = 'rex'$$) = 0,
  'familiare: la lapide sul cane altrui non viene applicata');
select test.ok((select count(*) from public.dogs where id = 'rex') = 0,
  'familiare che elimina il cane: esce dalla condivisione');
:come_A
select test.ok((select not deleted and data ->> 'name' = 'Rex' from public.dogs where id = 'rex'),
  'proprietario: il cane resta intatto dopo l''"eliminazione" del familiare');

-- ---------------------------------------------------------------------------
-- 7. Membri: un familiare non toglie gli altri; il proprietario non si toglie
-- ---------------------------------------------------------------------------
:come_A
select test.ok(length(public.create_invite('rex')) = 8, 'create_invite: codice di 8 caratteri dal server');
select public.create_invite('rex') as c1 \gset
select public.create_invite('rex') as c2 \gset
:come_B
select public.accept_invite(:'c1');
:come_D
select public.accept_invite(:'c2');
:come_B
select test.ok((select count(*) from public.dog_members where dog_id = 'rex') = 3, 'Rex ha 3 membri (A, B, D)');
select test.ok(test.rows($$delete from public.dog_members where dog_id = 'rex' and user_id = '00000000-0000-0000-0000-00000000000d'$$) = 0,
  'familiare: non toglie un altro familiare');
select test.ok(test.rows($$delete from public.dog_members where dog_id = 'rex' and user_id = '00000000-0000-0000-0000-00000000000a'$$) = 0,
  'familiare: non toglie il proprietario');
select test.ok(test.rows($$delete from public.invites where dog_id = 'rex'$$) = 0,
  'familiare: non cancella gli inviti del proprietario');
:come_A
select test.ok(test.rows($$delete from public.dog_members where dog_id = 'rex' and user_id = auth.uid()$$) = 0,
  'proprietario: non può togliersi (il cane resterebbe orfano)');
select test.ok(test.rows($$delete from public.dog_members where dog_id = 'rex' and user_id = '00000000-0000-0000-0000-00000000000d'$$) = 1,
  'proprietario: può togliere un familiare');

-- ---------------------------------------------------------------------------
-- 8. Voci: niente spostamenti, dati coerenti
-- ---------------------------------------------------------------------------
:come_B
insert into public.dogs (id, owner, data) values ('fido', auth.uid(), '{"id":"fido","name":"Fido"}');
select test.throws($$update public.entries set dog_id = 'fido' where id = 'e1'$$,
  'voce: non si sposta su un altro cane', 'spostare');
select test.throws($$update public.entries set kind = 'lab' where id = 'e1'$$,
  'voce: non cambia tipo', 'spostare');
select test.throws($$insert into public.entries (id, dog_id, kind, data) values ('e2', 'rex', 'log', '[1,2]')$$,
  'voce: data deve essere un oggetto JSON', 'violates check constraint');
select test.throws($$insert into public.entries (id, dog_id, kind, data) values ('e3', 'rex', 'log', '{"id":"e3","dogId":"fido"}')$$,
  'voce: dogId dentro data deve coincidere con dog_id', 'entries_data_ids');
select test.throws($$insert into public.entries (id, dog_id, kind, data) values ('e4', 'rex', 'log', '{"t":"x"}')$$,
  'voce: data senza id rifiutata', 'entries_data_ids');
select test.throws($$insert into public.entries (id, dog_id, kind, data)
  values ('e5', 'rex', 'log', jsonb_build_object('id','e5','dogId','rex','nota', repeat('x', 300000)))$$,
  'voce: oltre 256 KiB rifiutata', 'entries_data_size');
select test.throws($$update public.dogs set data = '{"id":"altro"}' where id = 'rex'$$,
  'cane: id dentro data deve coincidere', 'dogs_data_id');
insert into public.entries (id, dog_id, kind, data) values ('e6', 'rex', 'weight', '{"id":"e6","dogId":"rex","kg":30}');
update public.entries set deleted = true where id = 'e6';
select test.ok((select data = '{}'::jsonb from public.entries where id = 'e6'),
  'lapide: i dati della voce eliminata non restano sul server');

-- ---------------------------------------------------------------------------
-- 9. Limite di inviti attivi per cane
-- ---------------------------------------------------------------------------
:come_A
select public.create_invite('rex') from generate_series(1, 10 - (
  select count(*) from public.invites where dog_id = 'rex' and expires_at > now() and uses < max_uses)::int);
select test.throws($$select public.create_invite('rex')$$,
  'al massimo 10 inviti attivi per cane', 'troppi inviti');

-- ---------------------------------------------------------------------------
-- 10. Eliminazione dell'account
-- ---------------------------------------------------------------------------
:come_A
delete from public.invites where dog_id = 'rex';
select public.create_invite('rex') as c3 \gset
:come_F
insert into public.dogs (id, owner, data) values ('fiocco', auth.uid(), '{"id":"fiocco"}');
insert into public.entries (id, dog_id, kind, data) values ('f1', 'fiocco', 'log', '{"id":"f1","dogId":"fiocco"}');
select public.accept_invite(:'c3');
insert into public.entries (id, dog_id, kind, data) values ('f2', 'rex', 'log', '{"id":"f2","dogId":"rex"}');
select public.create_invite('fiocco');
select public.delete_my_account();
:come_admin
select test.ok(not exists (select 1 from auth.users where id = '00000000-0000-0000-0000-00000000000f'),
  'delete_my_account: l''utente non esiste più');
select test.ok(not exists (select 1 from public.dogs where id = 'fiocco')
  and not exists (select 1 from public.entries where dog_id = 'fiocco')
  and not exists (select 1 from public.invites where dog_id = 'fiocco'),
  'delete_my_account: i cani di cui era proprietario sono cancellati con i loro dati');
select test.ok(exists (select 1 from public.dogs where id = 'rex' and not deleted)
  and (select count(*) from public.entries where dog_id = 'rex') >= 2,
  'delete_my_account: il cane condiviso da altri resta intatto');
select test.ok((select updated_by is null from public.entries where id = 'f2'),
  'delete_my_account: le voci scritte nel cane altrui restano senza autore');
select test.ok(not exists (select 1 from public.dog_members where user_id = '00000000-0000-0000-0000-00000000000f')
  and not exists (select 1 from public.invite_attempts where user_id = '00000000-0000-0000-0000-00000000000f'),
  'delete_my_account: nessuna traccia tra membri e tentativi');

-- ---------------------------------------------------------------------------
-- 11. Funzioni security definer e permessi
-- ---------------------------------------------------------------------------
select test.ok(not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prosecdef
    and not coalesce(p.proconfig @> array['search_path=""'], false)),
  'ogni funzione security definer ha search_path vuoto',
  (select string_agg(p.proname, ', ') from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.prosecdef and not coalesce(p.proconfig @> array['search_path=""'], false)));
select test.ok(not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute')),
  'anon non può eseguire nessuna funzione di public',
  (select string_agg(p.proname, ', ') from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute')));
select test.ok(not exists (
  select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.prorettype = 'trigger'::regtype
    and has_function_privilege('authenticated', p.oid, 'execute')),
  'le funzioni dei trigger non sono eseguibili dagli utenti');
select test.ok(not exists (
  select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity),
  'RLS attiva su tutte le tabelle di public');
select test.ok(not exists (
  select 1 from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r'
    and (has_table_privilege('anon', c.oid, 'select,insert,update,delete,truncate')
         or has_table_privilege('authenticated', c.oid, 'truncate,references,trigger'))),
  'anon senza privilegi sulle tabelle; authenticated senza TRUNCATE/REFERENCES/TRIGGER');
-- Dirottamento del search_path: un utente che crea un suo schema con una
-- falsa tabella dog_members non influenza is_member.
create schema if not exists trappola;
create table if not exists trappola.dog_members (dog_id text, user_id uuid);
grant usage on schema trappola to authenticated;
grant select on trappola.dog_members to authenticated;
insert into trappola.dog_members values ('rex', '00000000-0000-0000-0000-00000000000c');
:come_C
set search_path = trappola, public;
select test.ok(not public.is_member('rex'), 'is_member non si lascia ingannare dal search_path del chiamante');
reset search_path;

-- ---------------------------------------------------------------------------
-- Riepilogo
-- ---------------------------------------------------------------------------
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
