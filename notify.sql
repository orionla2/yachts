CREATE OR REPLACE FUNCTION my_yacht.notify(message text)
  RETURNS void AS
$BODY$
declare
  msg text;
  _role name;
begin
  SELECT pg_notify('messanger',message) into msg;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION my_yacht.notify(text)
  OWNER TO postgres;

CREATE OR REPLACE FUNCTION my_yacht.login(
    email text,
    password text)
  RETURNS auth.jwt_claims AS
$BODY$
declare
  _role name;
  _verified boolean;
  _email text;
  result auth.jwt_claims;
begin
  -- check email and password

  select auth.user_role(login.email, login.password) into _role;
  if _role is null then
    raise invalid_password using message = 'invalid user or password';
  end if;

  -- check verified flag whether users
  -- have validated their emails
  _email := login.email;
  --select email from my_yacht.user as u where u.email=login.email limit 1 into _verified;
  --if not _verified then
  --  raise invalid_authorization_specification using message = 'user is not verified';
  --end if;
  --raise using message = _verified;
  select _role as role, login.email as email,
         extract(epoch from now())::integer + 60*60 as exp
  into result;
  NOTIFY messanger, 'test.message';
  return result;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION my_yacht.login(text, text)
  OWNER TO postgres;


CREATE OR REPLACE FUNCTION my_yacht.signup(
    firstname text,
    lastname text,
    email text,
    mobile text,
    password text)
  RETURNS void AS
$BODY$
declare
  msg text;
  emiter text;
begin
  emiter:= 'guest';
  insert into my_yacht.users (firstname, lastname, email, mobile, password,role, discount) values
    (signup.firstname, signup.lastname, signup.email, signup.mobile, signup.password, emiter, '0');
  end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION my_yacht.signup(text, text, text, text, text)
  OWNER TO postgres;

CREATE OR REPLACE FUNCTION my_yacht.update_users()
  RETURNS trigger AS
$BODY$
declare
  msg text;
  id text;
begin
  if tg_op = 'INSERT' then
    
    perform auth.clearance_for_role(new.role);
    new.role := 'user_role';
    insert into my_yacht.user
    (firstname,lastname,email,mobile,password,role,discount)
    values
      (new.firstname, new.lastname, new.email, new.mobile, new.password, new.role,new.discount);
      select lastval() into id;
    msg := id || '.' || user || '.newUser.email';
    SELECT pg_notify('messanger',msg) into msg;
    msg := id || '.' || user || '.newUser.sms';
    SELECT pg_notify('messanger',msg) into msg;
    msg := id || '.' || user || '.newUser.push';
    SELECT pg_notify('messanger',msg) into msg;
    SELECT pg_notify('messanger','234.manager.user.newUser.sms') into msg;
    return new;
  elsif tg_op = 'UPDATE' then
    -- no need to check clearance for old.role because
    -- an ineligible row would not have been available to update (http 404)
    perform auth.clearance_for_role(new.role);

    update my_yacht.user set
      firstname  = new.firstname,
      lastname  = new.lastname,
      email  = new.email,
      mobile   = new.mobile,
      password   = new.password,
      role   = new.role,
      discount   = new.discount
    where email = old.email;
    return new;
  elsif tg_op = 'DELETE' then
    -- no need to check clearance for old.role (see previous case)

    delete from my_yacht.user
    where email = old.email;
    return null;
  end if;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION my_yacht.update_users()
  OWNER TO postgres;

  GRANT EXECUTE ON FUNCTION my_yacht.update_user() TO guest;
GRANT EXECUTE ON FUNCTION my_yacht.signup(text, text) TO user_role;

CREATE OR REPLACE VIEW my_yacht.users AS 
 SELECT actual.firstname,
    actual.lastname,
    actual.email,
    actual.mobile,
    '***'::text AS password,
    actual.role,
    actual.discount
   FROM my_yacht."user" actual,
    ( SELECT pg_authid.rolname
           FROM pg_authid
          WHERE pg_has_role("current_user"(), pg_authid.oid, 'member'::text)) member_of
  WHERE actual.role::name = member_of.rolname || actual.role::name = 'user_role';

ALTER TABLE my_yacht.users
  OWNER TO postgres;

  GRANT USAGE, SELECT ON SEQUENCE user_id_seq TO guest;
  GRANT USAGE, SELECT ON SEQUENCES TO guest;
  grant all privileges on all sequences in schema public to guest;