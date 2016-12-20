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


DROP FUNCTION my_yacht.signup(text,text,text,text,text);
CREATE OR REPLACE FUNCTION my_yacht.signup(
    firstname text,
    lastname text,
    email text,
    mobile text,
    password text)
  RETURNS integer AS
$BODY$
declare
  msg text;
  emiter text;
  _id int;
begin
  emiter:= 'guest';
  insert into my_yacht.users (firstname, lastname, email, mobile, password,role, discount) values
    (signup.firstname, signup.lastname, signup.email, signup.mobile, signup.password, emiter, '0');
    
    SELECT id FROM my_yacht.user WHERE my_yacht.user.email = signup.email into _id;
    
  return _id;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

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


CREATE OR REPLACE FUNCTION my_yacht.createBooking(
  email text,
  start_date timestamp with time zone, 
  end_date timestamp with time zone, 
  guests integer, 
  firstname text,
  lastname text, 
  payment_type text, 
  phone text, 
  user_id integer, 
  y_id integer,
  additionals text) RETURNS boolean AS
$BODY$
declare
  msg text;
  ret_id int;
  json text;
  _usr_id int;
begin
  IF createBooking.user_id is null OR createBooking.user_id = 0 THEN
    insert into my_yacht.users (firstname, lastname, email, mobile, password,role, discount) values 
    (createBooking.firstname, createBooking.lastname, createBooking.email, createBooking.phone, createBooking.phone,user,0);
    SELECT id FROM my_yacht.user WHERE my_yacht.user.email = createBooking.email into ret_id;
    _usr_id := ret_id;
  ELSE
    _usr_id := user_id;
    --RAISE unique_violation USING MESSAGE = 'Not logged in. ' || ret_id;
  END IF;
  if my_yacht.checkdate(start_date,end_date) THEN
  insert into my_yacht.booking (y_id,start_date,end_date,user_id,payment,status,payment_type,discount) values
  (createBooking.y_id,createBooking.start_date,createBooking.end_date,_user_id,0,'pending',createBooking.payment_type);
  
  return true;
  ELSE
  return false;
  END if;
  
  
  json := createBooking.additionals::json->2;
  RAISE unique_violation USING MESSAGE = 'Logged in. User ID: ' || json;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION my_yacht.createBooking(text, timestamp with time zone, timestamp with time zone, integer, text, text, text, text, integer, integer,text)
  OWNER TO postgres

CREATE OR REPLACE FUNCTION my_yacht.checkDate(startDate timestamp with time zone, endDate timestamp with time zone) RETURNS boolean AS
$BODY$
declare
  temp_id int;
  ch_st_date int;
  ch_end_date int;
  json text;
begin
   if startDate >= endDate THEN
  RAISE unique_violation USING MESSAGE = 'Start date lower than End date';
   END if;
   
   select id from my_yacht.booking where start_date < startDate order by start_date asc limit 1 into temp_id;
   if temp_id is null THEN
  ch_st_date:= 1;
   ELSE
  select 1 from my_yacht.booking where id = temp_id AND end_date < startDate order by start_date limit 1 into ch_st_date;
   END if;

   select id from my_yacht.booking where end_date > startDate order by start_date desc limit 1 into temp_id;
   if temp_id is null THEN
  ch_end_date:= 1;
   ELSE 
  select 1 from my_yacht.booking where id = temp_id AND start_date > endDate order by start_date limit 1 into ch_end_date;
   END if;
   
   if ch_st_date = 1 AND ch_end_date = 1 THEN
  return true;
   ELSE
  return false;
   END if;
   --RAISE unique_violation USING MESSAGE = 'Logged in. User ID: ' || sDate;
end
$BODY$
  LANGUAGE plpgsql VOLATILE
  SECURITY DEFINER
  COST 100;
  
ALTER FUNCTION my_yacht.checkDate(timestamp with time zone,timestamp with time zone)
  OWNER TO postgres



  
