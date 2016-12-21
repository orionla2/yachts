-- Deploy f_login
-- requires: types

BEGIN;

SET search_path = my_yacht, pg_catalog;
CREATE OR REPLACE FUNCTION my_yacht.login(email text, password text) RETURNS auth.jwt_claims
LANGUAGE plpgsql
AS $$
declare
  _role name;
  _verified boolean;
  _email text;
  result auth.jwt_claims;
begin
  select auth.user_role(login.email, login.password) into _role;
  if _role is null then
    raise invalid_password using message = 'invalid user or password';
  end if;
  _email := login.email;
  select _role as role, login.email as email,
         extract(epoch from now())::integer + 60*60 as exp
  into result;
  return result;
end;
$$;


ALTER FUNCTION my_yacht.login(email text, password text) OWNER TO postgres;

GRANT ALL ON FUNCTION login(email text, password text) TO guest;
GRANT ALL ON FUNCTION login(email text, password text) TO manager;
GRANT ALL ON FUNCTION login(email text, password text) TO user_role;


COMMIT;
