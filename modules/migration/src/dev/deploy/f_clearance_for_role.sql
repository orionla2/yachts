-- Deploy f_clearance_for_role
-- requires: types

BEGIN;

SET search_path = auth, pg_catalog;
CREATE OR REPLACE FUNCTION clearance_for_role(u name) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  ok boolean;
begin
  select exists (
      select rolname
      from pg_authid
      where pg_has_role(current_user, oid, 'member')
            and rolname = u
  ) into ok;
  if not ok then
    raise invalid_password using message =
      'current user not member of role ' || u;
  end if;
end
$$;


ALTER FUNCTION auth.clearance_for_role(u name) OWNER TO postgres;


COMMIT;
