-- Verify users

BEGIN;

SELECT 1/count(*) FROM pg_roles WHERE rolname='manager';
SELECT 1/count(*) FROM pg_roles WHERE rolname='user_role';
SELECT 1/count(*) FROM pg_roles WHERE rolname='guest';
SELECT 1/count(*) FROM pg_roles WHERE rolname='authenticator';

ROLLBACK;
