-- Deploy f_signup
-- requires: types

BEGIN;

SET search_path = my_yacht, pg_catalog;
CREATE OR REPLACE FUNCTION signup(firstname text, lastname text, email text, mobile text, password text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  msg text;
  emiter text;
begin
  emiter:= 'guest';
  insert into my_yacht.users (firstname, lastname, email, mobile, password,role, discount) values
    (signup.firstname, signup.lastname, signup.email, signup.mobile, signup.password, emiter, '0');
end;
$$;


ALTER FUNCTION my_yacht.signup(firstname text, lastname text, email text, mobile text, password text) OWNER TO postgres;
GRANT ALL ON FUNCTION signup(firstname text, lastname text, email text, mobile text, password text) TO guest;


COMMIT;
