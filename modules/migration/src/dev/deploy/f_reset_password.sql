-- Deploy f_reset_password
-- requires: types

BEGIN;

SET search_path = my_yacht, pg_catalog;
CREATE OR REPLACE FUNCTION reset_password(email text, token uuid, password text) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  tok uuid;
begin
  if exists(select 1 from auth.tokens
  where tokens.email = reset_password.email
        and tokens.token = reset_password.token
        and token_type = 'reset') then
    update my_yacht.users set password=reset_password.password
    where users.email = reset_password.email;

    delete from auth.tokens
    where tokens.email = reset_password.email
          and tokens.token = reset_password.token
          and token_type = 'reset';
  else
    raise invalid_password using message =
      'invalid user or token';
  end if;
  delete from auth.tokens
  where token_type = 'reset'
        and tokens.email = reset_password.email;

  select gen_random_uuid() into tok;
  insert into auth.tokens (token, token_type, email)
  values (tok, 'reset', reset_password.email);
  perform pg_notify('reset',
                    json_build_object(
                        'email', reset_password.email,
                        'token', tok
                    )::text
  );
end;
$$;


ALTER FUNCTION my_yacht.reset_password(email text, token uuid, password text) OWNER TO postgres;

GRANT ALL ON FUNCTION reset_password(email text, token uuid, password text) TO manager;
GRANT ALL ON FUNCTION reset_password(email text, token uuid, password text) TO user_role;



COMMIT;
