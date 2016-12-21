-- Deploy f_user_role
-- requires: types

BEGIN;

SET search_path = auth, pg_catalog;
CREATE OR REPLACE FUNCTION user_role(ch_email text, password text) RETURNS name
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  _role text;
  _cur_role text;
begin
  select role from my_yacht.user as u
  where u.email = user_role.ch_email and u.password = crypt(user_role.password, u.password) into _role;
  return _role;
end;
$$;


ALTER FUNCTION auth.user_role(ch_email text, password text) OWNER TO postgres;


COMMIT;
