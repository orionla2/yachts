-- Verify appschema

BEGIN;

-- XXX Add verifications here.
SELECT pg_catalog.has_schema_privilege('my_yacht', 'usage');
SELECT pg_catalog.has_schema_privilege('auth', 'usage');

SELECT 1/count(*) FROM pg_extension WHERE extname = 'plpgsql';
SELECT 1/count(*) FROM pg_extension WHERE extname = 'pgcrypto';

SELECT token, token_type, email, created_at FROM auth.tokens WHERE FALSE;
--- TODO make checking all tables

SELECT firstname, lastname, email, mobile, password, role, discount FROM my_yacht.users WHERE FALSE;
--- TODO make checking all views

SELECT has_function_privilege('auth.clearance_for_role(name)', 'execute');
--- TODO make checking all functions

SELECT 1/count(*) FROM pg_class WHERE relkind = 'S' and relname = 'additional_id_seq';
--- TODO make checking all sequences

ROLLBACK;
