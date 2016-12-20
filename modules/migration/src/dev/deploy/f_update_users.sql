-- Deploy f_update_users
-- requires: types

BEGIN;

SET search_path = my_yacht, pg_catalog;
CREATE OR REPLACE FUNCTION update_users() RETURNS trigger
LANGUAGE plpgsql
AS $$
declare
  msg text;
  id int;
  m_id text;
begin
  if tg_op = 'INSERT' then

    perform auth.clearance_for_role(new.role);
    new.role := 'user_role';
    insert into my_yacht.user
    (firstname,lastname,email,mobile,password,role,discount)
    values
      (new.firstname, new.lastname, new.email, new.mobile, new.password, new.role,new.discount);
    select lastval() into id;
    FOR m_id IN SELECT id FROM my_yacht.user WHERE role = 'manager'
    LOOP
      msg := id || '.' || m_id ||'.user.newUser.email';
      SELECT pg_notify('messanger',msg) into msg;
      msg := id || '.' || m_id ||'.user.newUser.push';
      SELECT pg_notify('messanger',msg) into msg;
    END LOOP;
    msg := id || '.' || id ||'.user.newUser.email';
    SELECT pg_notify('messanger',msg) into msg;
    msg := id || '.' || id ||'.user.newUser.sms';
    SELECT pg_notify('messanger',msg) into msg;

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
$$;


ALTER FUNCTION my_yacht.update_users() OWNER TO postgres;

GRANT ALL ON FUNCTION my_yacht.update_users() TO guest;

COMMIT;
