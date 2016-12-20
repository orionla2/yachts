-- Verify types

BEGIN;

select 1/count(*) from pg_catalog.pg_type where typname='jwt_claims';
select 1/count(*) from pg_catalog.pg_type where typname='token_type_enum';

ROLLBACK;
