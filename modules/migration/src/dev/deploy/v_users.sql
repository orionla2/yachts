-- Deploy v_users
-- requires: types

BEGIN;

--
-- Name: users; Type: VIEW; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE VIEW users AS
 SELECT actual.firstname,
    actual.lastname,
    actual.email,
    actual.mobile,
    '***'::text AS password,
    actual.role,
    actual.discount
   FROM "user" actual,
    ( SELECT pg_authid.rolname
           FROM pg_authid
          WHERE pg_has_role("current_user"(), pg_authid.oid, 'member'::text)) member_of
  WHERE ((actual.role)::name = member_of.rolname);


ALTER TABLE users OWNER TO postgres;
CREATE TRIGGER update_users INSTEAD OF INSERT OR DELETE OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_users();

--
-- Name: users; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,UPDATE ON TABLE users TO manager;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,UPDATE ON TABLE users TO user_role;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,UPDATE ON TABLE users TO guest;


COMMIT;
