-- Revert a_pg_authid

BEGIN;

REVOKE SELECT ON TABLE pg_catalog.pg_authid FROM manager;
REVOKE SELECT ON TABLE pg_catalog.pg_authid FROM user_role;
REVOKE SELECT ON TABLE pg_catalog.pg_authid FROM guest;

COMMIT;
