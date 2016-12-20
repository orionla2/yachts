-- Deploy a_pg_authid
-- requires: users

BEGIN;

SET search_path = pg_catalog;

--
-- Name: pg_authid; Type: ACL; Schema: pg_catalog; Owner: postgres
--

GRANT SELECT ON TABLE pg_authid TO manager;
GRANT SELECT ON TABLE pg_authid TO user_role;
GRANT SELECT ON TABLE pg_authid TO guest;


COMMIT;
