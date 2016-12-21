-- Deploy f_check_role_exists
-- requires: types

BEGIN;

SET search_path = auth, pg_catalog;

--
-- Name: check_role_exists(); Type: FUNCTION; Schema: auth; Owner: postgres
--

CREATE OR REPLACE FUNCTION check_role_exists() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if not exists (select 1 from pg_roles as r where r.rolname = new.role) then
    raise foreign_key_violation using message =
      'unknown database role: ' || new.role;
    return null;
  end if;
  return new;
end
$$;


ALTER FUNCTION auth.check_role_exists() OWNER TO postgres;

COMMIT;
