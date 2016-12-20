--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.1
-- Dumped by pg_dump version 9.6.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgres; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA auth;


ALTER SCHEMA auth OWNER TO postgres;

--
-- Name: my_yacht; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA my_yacht;


ALTER SCHEMA my_yacht OWNER TO postgres;

--
-- Name: sqitch; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA sqitch;


ALTER SCHEMA sqitch OWNER TO postgres;

--
-- Name: SCHEMA sqitch; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA sqitch IS 'Sqitch database deployment metadata v1.0.';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET search_path = auth, pg_catalog;

--
-- Name: jwt_claims; Type: TYPE; Schema: auth; Owner: postgres
--

CREATE TYPE jwt_claims AS (
	role text,
	email text,
	exp integer
);


ALTER TYPE jwt_claims OWNER TO postgres;

SET search_path = public, pg_catalog;

--
-- Name: token_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE token_type_enum AS ENUM (
    'validation',
    'reset'
);


ALTER TYPE token_type_enum OWNER TO postgres;

SET search_path = auth, pg_catalog;

--
-- Name: check_role_exists(); Type: FUNCTION; Schema: auth; Owner: postgres
--

CREATE FUNCTION check_role_exists() RETURNS trigger
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

--
-- Name: clearance_for_role(name); Type: FUNCTION; Schema: auth; Owner: postgres
--
SET search_path = auth, pg_catalog;
CREATE FUNCTION clearance_for_role(u name) RETURNS void
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

--
-- Name: current_email(); Type: FUNCTION; Schema: auth; Owner: postgres
--
SET search_path = auth, pg_catalog;
CREATE FUNCTION current_email() RETURNS text
    LANGUAGE plpgsql
    AS $$
begin
  return current_setting('postgrest.claims.email');
end;
$$;


ALTER FUNCTION auth.current_email() OWNER TO postgres;

--
-- Name: encrypt_pass(); Type: FUNCTION; Schema: auth; Owner: postgres
--
SET search_path = auth, pg_catalog;
CREATE FUNCTION encrypt_pass() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if tg_op = 'INSERT' or new.password <> old.password then
    new.password = crypt(new.password, gen_salt('bf'));
  end if;
  return new;
end
$$;


ALTER FUNCTION auth.encrypt_pass() OWNER TO postgres;

--
-- Name: send_validation(); Type: FUNCTION; Schema: auth; Owner: postgres
--
SET search_path = auth, pg_catalog;
CREATE FUNCTION send_validation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  tok uuid;
begin
  select gen_random_uuid() into tok;
  insert into auth.tokens (token, token_type, email)
  values (tok, 'validation', new.email);
  perform pg_notify('validate',
                    json_build_object(
                        'email', new.email,
                        'token', tok,
                        'token_type', 'validation'
                    )::text
  );
  return new;
end
$$;


ALTER FUNCTION auth.send_validation() OWNER TO postgres;

--
-- Name: user_role(text, text); Type: FUNCTION; Schema: auth; Owner: postgres
--
SET search_path = auth, pg_catalog;
CREATE FUNCTION user_role(ch_email text, password text) RETURNS name
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

SET search_path = my_yacht, pg_catalog;

--
-- Name: checkdate(timestamp with time zone, timestamp with time zone, integer); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--

CREATE FUNCTION checkdate(startdate timestamp with time zone, enddate timestamp with time zone, preperation integer) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  temp_id int;
  ch_st_date int;
  ch_end_date int;
  _startDate timestamp with time zone;
  _endDate timestamp with time zone;
  _prepTime text = preperation::text || ' hour';
begin
   _startDate = startdate - (_prepTime || ' hour')::interval;
   _endDate = enddate + (_prepTime || ' hour')::interval;
   if startDate >= endDate THEN
	RAISE unique_violation USING MESSAGE = 'Start date lower than End date';
   END if;

   select id from my_yacht.booking where start_date < _startDate order by start_date desc limit 1 into temp_id;

   if temp_id is null THEN
	ch_st_date:= 1;
   ELSE
	select 1 from my_yacht.booking where id = temp_id AND end_date <= _startDate order by start_date limit 1 into ch_st_date;
   END if;

   select id from my_yacht.booking where end_date >= _startDate order by start_date asc limit 1 into temp_id;

   if temp_id is null THEN
	ch_end_date:= 1;
   ELSE
	select 1 from my_yacht.booking where id = temp_id AND start_date >= _endDate order by start_date limit 1 into ch_end_date;
   END if;

   if ch_st_date = 1 AND ch_end_date = 1 THEN
	return true;
   ELSE
	return false;
   END if;
   --RAISE unique_violation USING MESSAGE = 'Logged in. User ID: ' || sDate;
end
$$;


ALTER FUNCTION my_yacht.checkdate(startdate timestamp with time zone, enddate timestamp with time zone, preperation integer) OWNER TO postgres;

--
-- Name: createbooking(text, timestamp with time zone, timestamp with time zone, integer, text, text, text, text, integer, integer, text); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
CREATE FUNCTION createbooking(email text, start_date timestamp with time zone, end_date timestamp with time zone, guests integer, firstname text, lastname text, payment_type text, phone text, user_id integer, y_id integer, additionals text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  ret_id int;
  sum int = 0;
  _extras int;
  _packages int;
  _money int;
  _amount int;
  _usr_id int;
  i json;
  booking_id int;
begin

  IF createBooking.user_id is null OR createBooking.user_id = 0 THEN
    PERFORM my_yacht.signup(createBooking.firstname, createBooking.lastname, createBooking.email, createBooking.phone, createBooking.phone);
    SELECT my_yacht.getid(email) into ret_id;
    _usr_id := ret_id;
  ELSE
    _usr_id := user_id;
  END IF;
  --RAISE unique_violation USING MESSAGE = 'stop';
  IF (SELECT 1 FROM my_yacht.user WHERE id = _usr_id) THEN
	IF my_yacht.checkdate(start_date,end_date,1) THEN
		FOR i IN SELECT json_array_elements(createBooking.additionals::json)
		LOOP
			select i::json->>'money' into _money::text;
			if _money::int > 0 then
				sum = _money::int + sum::int;
			end if;
		END LOOP;
		insert into my_yacht.booking (y_id,start_date,end_date,user_id,payment,status,payment_type,discount) values
		(createBooking.y_id,createBooking.start_date,createBooking.end_date,_usr_id,sum,1,createBooking.payment_type,0);
		SELECT lastval() INTO booking_id;
		FOR i IN SELECT json_array_elements(createBooking.additionals::json)
		LOOP
			select i::json->>'extrasId' into _extras::text;
			select i::json->>'packageId' into _packages::text;
			select i::json->>'money' into _money::text;
			select i::json->>'amount' into _amount::text;

			insert into my_yacht.additional (booking_id,extras_id,packages_id,guests,amount,money) VALUES
			(booking_id,_extras::int,_packages::int,createBooking.guests,_amount::int,_money::int);
			--RAISE unique_violation USING MESSAGE = _extras || ' ' || _amount;
		END LOOP;
		return true;
	ELSE
		return false;
	END IF;
  ELSE
	return false;
  END IF;
end
$$;


ALTER FUNCTION my_yacht.createbooking(email text, start_date timestamp with time zone, end_date timestamp with time zone, guests integer, firstname text, lastname text, payment_type text, phone text, user_id integer, y_id integer, additionals text) OWNER TO postgres;

--
-- Name: getid(text); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
CREATE FUNCTION getid(email text) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
  ret_id int;
begin
	return(SELECT id FROM my_yacht.user WHERE my_yacht.user.email = getId.email);
end
$$;


ALTER FUNCTION my_yacht.getid(email text) OWNER TO postgres;

--
-- Name: login(text, text); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
CREATE FUNCTION login(email text, password text) RETURNS auth.jwt_claims
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION my_yacht.login(email text, password text) OWNER TO postgres;

--
-- Name: notify(text); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
CREATE FUNCTION notify(message text) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  msg text;
  _role name;
begin
  SELECT pg_notify('messanger',message) into msg;
end;
$$;


ALTER FUNCTION my_yacht.notify(message text) OWNER TO postgres;

--
-- Name: request_password_reset(text); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
CREATE FUNCTION request_password_reset(email text) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare
  tok uuid;
begin
  delete from auth.tokens
  where token_type = 'reset'
        and tokens.email = request_password_reset.email;

  select gen_random_uuid() into tok;
  insert into auth.tokens (token, token_type, email)
  values (tok, 'reset', request_password_reset.email);
  perform pg_notify('reset',
                    json_build_object(
                        'email', request_password_reset.email,
                        'token', tok,
                        'token_type', 'reset'
                    )::text
  );
end;
$$;


ALTER FUNCTION my_yacht.request_password_reset(email text) OWNER TO postgres;

--
-- Name: reset_password(text, uuid, text); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
CREATE FUNCTION reset_password(email text, token uuid, password text) RETURNS void
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

--
-- Name: signup(text, text, text, text, text); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
CREATE FUNCTION signup(firstname text, lastname text, email text, mobile text, password text) RETURNS void
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

--
-- Name: update_users(); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
CREATE FUNCTION update_users() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  msg text;
  id int;
begin
  if tg_op = 'INSERT' then

    perform auth.clearance_for_role(new.role);
    new.role := 'user_role';
    insert into my_yacht.user
    (firstname,lastname,email,mobile,password,role,discount)
    values
      (new.firstname, new.lastname, new.email, new.mobile, new.password, new.role,new.discount);
    select lastval() into id;
    msg := id || '.manager.user.newUser.email';
    SELECT pg_notify('messanger',msg) into msg;
    msg := id || '.manager.user.newUser.push';
    SELECT pg_notify('messanger',msg) into msg;
    msg := id || '.user_role.user.newUser.email';
    SELECT pg_notify('messanger',msg) into msg;
    msg := id || '.user_role.user.newUser.sms';
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


SET search_path = auth, pg_catalog;

SET default_tablespace = '';
SET default_with_oids = false;

--
-- Name: tokens; Type: TABLE; Schema: auth; Owner: postgres
--

CREATE TABLE tokens (
    token uuid NOT NULL,
    token_type public.token_type_enum NOT NULL,
    email text NOT NULL,
    created_at timestamp with time zone DEFAULT ('now'::text)::date NOT NULL
);


ALTER TABLE tokens OWNER TO postgres;

SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
--
-- Name: additional; Type: TABLE; Schema: my_yacht; Owner: postgres
--

CREATE TABLE additional (
    id integer NOT NULL,
    booking_id integer NOT NULL,
    extras_id integer,
    packages_id integer,
    guests integer NOT NULL,
    amount integer NOT NULL,
    money numeric
);


ALTER TABLE additional OWNER TO postgres;

--
-- Name: additional_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE additional_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE additional_id_seq OWNER TO postgres;

--
-- Name: additional_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE additional_id_seq OWNED BY additional.id;


--
-- Name: booking; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;

CREATE TABLE booking (
    id integer NOT NULL,
    y_id integer NOT NULL,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone NOT NULL,
    user_id integer NOT NULL,
    payment numeric,
    status integer NOT NULL,
    payment_type character varying(80) NOT NULL,
    discount numeric(2,2)
);


ALTER TABLE booking OWNER TO postgres;

--
-- Name: booking_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE booking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE booking_id_seq OWNER TO postgres;

--
-- Name: booking_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE booking_id_seq OWNED BY booking.id;


--
-- Name: devices; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;

CREATE TABLE devices (
    id integer NOT NULL,
    user_id integer NOT NULL,
    platform character varying(45) NOT NULL,
    device_id character varying(45) NOT NULL
);


ALTER TABLE devices OWNER TO postgres;

--
-- Name: devices_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE devices_id_seq OWNER TO postgres;

--
-- Name: devices_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE devices_id_seq OWNED BY devices.id;


--
-- Name: download; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE download (
    id integer NOT NULL,
    tagline character varying(80) NOT NULL,
    filename text NOT NULL
);


ALTER TABLE download OWNER TO postgres;

--
-- Name: download_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE download_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE download_id_seq OWNER TO postgres;

--
-- Name: download_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE download_id_seq OWNED BY download.id;


--
-- Name: extras; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE extras (
    id integer NOT NULL,
    title character varying(45) NOT NULL,
    price numeric NOT NULL,
    min_charge integer NOT NULL,
    unit character varying(45) NOT NULL,
    description character varying(255) NOT NULL,
    status boolean DEFAULT true
);


ALTER TABLE extras OWNER TO postgres;

--
-- Name: extras_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE extras_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE extras_id_seq OWNER TO postgres;

--
-- Name: extras_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE extras_id_seq OWNED BY extras.id;


--
-- Name: file; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE file (
    id integer NOT NULL,
    type character varying(45) NOT NULL,
    url text NOT NULL,
    y_id integer NOT NULL
);


ALTER TABLE file OWNER TO postgres;

--
-- Name: file_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE file_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE file_id_seq OWNER TO postgres;

--
-- Name: file_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE file_id_seq OWNED BY file.id;


--
-- Name: invoice; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE invoice (
    id integer NOT NULL,
    booking_id integer NOT NULL,
    invoice_num integer NOT NULL,
    title text NOT NULL,
    amount integer NOT NULL,
    rate numeric NOT NULL,
    subtotal numeric NOT NULL,
    total numeric,
    status boolean,
    invoice_date date NOT NULL
);


ALTER TABLE invoice OWNER TO postgres;

--
-- Name: invoice_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE invoice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE invoice_id_seq OWNER TO postgres;

--
-- Name: invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE invoice_id_seq OWNED BY invoice.id;


--
-- Name: packages; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE packages (
    id integer NOT NULL,
    title character varying(45) NOT NULL,
    price numeric NOT NULL,
    min_charge integer NOT NULL,
    description character varying(255),
    y_id integer,
    status boolean DEFAULT true,
    unit character varying(40) NOT NULL
);


ALTER TABLE packages OWNER TO postgres;

--
-- Name: packages_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE packages_id_seq OWNER TO postgres;

--
-- Name: packages_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE packages_id_seq OWNED BY packages.id;


--
-- Name: payment; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE payment (
    id integer NOT NULL,
    invoice_id integer NOT NULL,
    type character varying(45) NOT NULL,
    user_id integer NOT NULL,
    value numeric
);


ALTER TABLE payment OWNER TO postgres;

--
-- Name: payment_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE payment_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE payment_id_seq OWNER TO postgres;

--
-- Name: payment_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE payment_id_seq OWNED BY payment.id;


--
-- Name: user; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE "user" (
    id integer NOT NULL,
    firstname character varying(80),
    lastname character varying(80) NOT NULL,
    email character varying(255) NOT NULL,
    mobile character varying(16) NOT NULL,
    password character varying(64) NOT NULL,
    role character varying(45) NOT NULL,
    discount numeric(2,2) DEFAULT 0,
    status boolean DEFAULT true NOT NULL,
    CONSTRAINT chk_email CHECK (((email)::text ~* '^.+@.+\..+$'::text)),
    CONSTRAINT chk_pass CHECK ((length((password)::text) < 65))
);


ALTER TABLE "user" OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_id_seq OWNER TO postgres;

--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE user_id_seq OWNED BY "user".id;


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

--
-- Name: yacht; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE yacht (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    content text NOT NULL,
    readmore text NOT NULL,
    status boolean DEFAULT true NOT NULL
);


ALTER TABLE yacht OWNER TO postgres;

--
-- Name: yacht_id_seq; Type: SEQUENCE; Schema: my_yacht; Owner: postgres
--

CREATE SEQUENCE yacht_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE yacht_id_seq OWNER TO postgres;

--
-- Name: yacht_id_seq; Type: SEQUENCE OWNED BY; Schema: my_yacht; Owner: postgres
--

ALTER SEQUENCE yacht_id_seq OWNED BY yacht.id;




SET search_path = my_yacht, pg_catalog;

--
-- Name: additional id; Type: DEFAULT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY additional ALTER COLUMN id SET DEFAULT nextval('additional_id_seq'::regclass);


--
-- Name: booking id; Type: DEFAULT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY booking ALTER COLUMN id SET DEFAULT nextval('booking_id_seq'::regclass);


--
-- Name: devices id; Type: DEFAULT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY devices ALTER COLUMN id SET DEFAULT nextval('devices_id_seq'::regclass);


--
-- Name: download id; Type: DEFAULT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY download ALTER COLUMN id SET DEFAULT nextval('download_id_seq'::regclass);


--
-- Name: extras id; Type: DEFAULT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY extras ALTER COLUMN id SET DEFAULT nextval('extras_id_seq'::regclass);


--
-- Name: file id; Type: DEFAULT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY file ALTER COLUMN id SET DEFAULT nextval('file_id_seq'::regclass);


--
-- Name: invoice id; Type: DEFAULT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY invoice ALTER COLUMN id SET DEFAULT nextval('invoice_id_seq'::regclass);


--
-- Name: packages id; Type: DEFAULT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY packages ALTER COLUMN id SET DEFAULT nextval('packages_id_seq'::regclass);


--
-- Name: payment id; Type: DEFAULT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY payment ALTER COLUMN id SET DEFAULT nextval('payment_id_seq'::regclass);


--
-- Name: user id; Type: DEFAULT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY "user" ALTER COLUMN id SET DEFAULT nextval('user_id_seq'::regclass);


--
-- Name: yacht id; Type: DEFAULT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY yacht ALTER COLUMN id SET DEFAULT nextval('yacht_id_seq'::regclass);


SET search_path = auth, pg_catalog;

--
-- Data for Name: tokens; Type: TABLE DATA; Schema: auth; Owner: postgres
--

COPY tokens (token, token_type, email, created_at) FROM stdin;
\.


SET search_path = my_yacht, pg_catalog;

--
-- Data for Name: additional; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY additional (id, booking_id, extras_id, packages_id, guests, amount, money) FROM stdin;
3	12	11	\N	50	3	19750
4	12	15	\N	50	5	64380
5	12	\N	15	50	1	\N
6	13	11	\N	50	3	19750
7	13	15	\N	50	5	64380
8	13	\N	15	50	1	\N
9	14	11	\N	50	3	19750
10	14	15	\N	50	5	64380
11	14	\N	15	50	1	\N
12	15	11	\N	50	3	19750
13	15	15	\N	50	5	64380
14	15	\N	15	50	1	\N
15	16	11	\N	50	3	19750
16	16	15	\N	50	5	64380
17	16	\N	15	50	1	\N
18	17	11	\N	50	3	19750
19	17	15	\N	50	5	64380
20	17	\N	15	50	1	\N
\.


--
-- Name: additional_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('additional_id_seq', 20, true);


--
-- Data for Name: booking; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY booking (id, y_id, start_date, end_date, user_id, payment, status, payment_type, discount) FROM stdin;
3	7	2016-10-20 06:00:00+00	2016-10-20 14:00:00+00	22	2000	1	cash	0.00
4	7	2016-10-22 10:00:00+00	2016-10-22 18:00:00+00	22	2000	1	cash	0.00
12	7	2016-10-21 11:00:00+00	2016-10-21 15:00:00+00	22	84130	1	Method 1	0.00
13	7	2016-11-21 11:00:00+00	2016-11-21 15:00:00+00	33	84130	1	Method 1	0.00
14	7	2016-09-21 11:00:00+00	2016-09-21 15:00:00+00	36	84130	1	Method 1	0.00
15	7	2016-09-22 11:00:00+00	2016-09-22 15:00:00+00	37	84130	1	Method 1	0.00
16	7	2016-09-23 11:00:00+00	2016-09-23 15:00:00+00	38	84130	1	Method 1	0.00
17	7	2016-09-24 11:00:00+00	2016-09-24 15:00:00+00	39	84130	1	Method 1	0.00
\.


--
-- Name: booking_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('booking_id_seq', 17, true);


--
-- Data for Name: devices; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY devices (id, user_id, platform, device_id) FROM stdin;
11	23	Mozilla/5.0 (compatible; MSIE 10.0; Windows N	Mozilla/5.0 (Windows NT 5.2; Win64; x64; rv:1
12	25	Mozilla/5.0 (Windows; U; Windows NT 5.0) Appl	Mozilla/5.0 (compatible; MSIE 7.0; Windows NT
13	23	Mozilla/5.0 (Windows; U; Windows NT 6.0) Appl	Mozilla/5.0 (Windows NT 6.1; WOW64; rv:9.6) G
14	22	Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_	Mozilla/5.0 (Windows; U; Windows NT 5.0) Appl
15	26	Mozilla/5.0 (Windows NT 6.2; Trident/7.0; Tou	Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7.3
16	24	Mozilla/5.0 (Windows; U; Windows NT 6.0) Appl	Mozilla/5.0 (Windows; U; Windows NT 5.2) Appl
17	22	Mozilla/5.0 (Windows NT 5.3; rv:7.8) Gecko/20	Mozilla/5.0 (Windows NT 6.3; Win64; x64; rv:1
18	25	Mozilla/5.0 (compatible; MSIE 10.0; Windows N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2
19	23	Mozilla/5.0 (compatible; MSIE 9.0; Windows NT	Mozilla/5.0 (Windows NT 6.0; rv:14.6) Gecko/2
20	25	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3	Mozilla/5.0 (compatible; MSIE 10.0; Windows N
\.


--
-- Name: devices_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('devices_id_seq', 20, true);


--
-- Data for Name: download; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY download (id, tagline, filename) FROM stdin;
\.


--
-- Name: download_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('download_id_seq', 1, true);


--
-- Data for Name: extras; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY extras (id, title, price, min_charge, unit, description, status) FROM stdin;
10	Jet Boat	500	1	Per Trip / Hour	Upto 7 People	t
11	Bar Man	150	4	Per hour	Professional Barman	t
12	Waiters / Staff	75	4	Per hour	Professional Waiters	t
13	Security/Bouncers	100	4	Per hour	VIP Background Security	t
14	Hostess	150	4	Per hour	Presentable & Professional	t
15	Photographer	500	4	Per hour	Standard Photographer	t
16	DJ	500	4	Per hour	House DJs, Excludes equipment	t
17	Professional Music equipment	100	0	Per event	CDJ(Pioneer R1), 4 Speaker+Sub, Mic	t
18	Theme/ Decorations	0	0	Per event	As Per Actual + 25% Surcharge	t
\.


--
-- Name: extras_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('extras_id_seq', 18, true);


--
-- Data for Name: file; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY file (id, type, url, y_id) FROM stdin;
11	description	http://lorempixel.com/640/480/transport	7
12	image	http://lorempixel.com/640/480/transport	8
13	drawing	http://lorempixel.com/640/480/transport	10
14	image	http://lorempixel.com/640/480/transport	6
15	image	http://lorempixel.com/640/480/transport	8
16	description	http://lorempixel.com/640/480/transport	6
17	image	http://lorempixel.com/640/480/transport	10
18	drawing	http://lorempixel.com/640/480/transport	9
19	drawing	http://lorempixel.com/640/480/transport	6
20	description	http://lorempixel.com/640/480/transport	9
\.


--
-- Name: file_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('file_id_seq', 20, true);


--
-- Data for Name: invoice; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY invoice (id, booking_id, invoice_num, title, amount, rate, subtotal, total, status, invoice_date) FROM stdin;
\.


--
-- Name: invoice_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('invoice_id_seq', 1, false);


--
-- Data for Name: packages; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY packages (id, title, price, min_charge, description, y_id, status, unit) FROM stdin;
15	Charter LOTUS 220	10000	4	Charter LOTUS 220	6	t	Per hour
16	Charter DESERT ROSE 155	5000	4	Charter DESERT ROSE 155	7	t	Per hour
17	Charter VIRGO 88	2000	4	Charter VIRGO 88	8	t	Per hour
18	Charter KHAN 90	2000	4	Charter KHAN 90	9	t	Per hour
19	Charter PLUTO 75	1250	4	Charter PLUTO 75	10	t	Per hour
20	Premium Package (Meal+Drinks)	395	50	5* Catered Premium Buffet + Live Station; Unlimited Premium Drinks for 4 Hours; Soft Drinks, Juices & Mixers; Bar Tender, Staff & Security; Security & Hostess; DJ, Music equip, Table Setting; 5* Hotel Staff	\N	t	Per guest
21	Standard Package (Meal+Drinks)	295	50	5* Catered Standard Buffet + Live Station; Unlimited Standard Drinks for 4 Hours; Soft Drinks, Juices & Mixers; Bar Tender, Staff & Security; Security; Table Setting; 5* Hotel Staff	\N	t	Per guest
22	Drinks Premium	245	50	Unlimited Premium Drinks for 4 Hours; Bar Tender, Staff & Security; Mixers, Juices & Soft Drinks; Packaged Snacks; Hostess, DJ & Music Equip	\N	t	Per guest
23	Drinks Standard	145	50	Unlimited Standard Drinks for 4 Hours; Bar Tender, Staff & Security; Mixers, Juices & Soft Drinks	\N	t	Per guest
24	Buffet Meal Premium	245	50	5* Catered Premium Buffet + Live Station & Soft Drinks; Table Setting; 5* Hotel Staff; Hostess; Music Equip	\N	t	Per guest
25	Buffet Meal Standard	145	50	5* Catered Standard Buffet & Soft Drinks; Table Setting; 5* Hotel Staff	\N	t	Per guest
26	Soft Drinks	25	100	Unlimited Soft Drinks, Juices, Water & Ice; 2 Waiters, 2 Cleaners	\N	t	Per guest
27	Catering Corkage (Lotus&Desert Rose)	50	100	4 Helpers/Cleaners; 2Hrs Setup time + 1 Hour Cleaning time	\N	t	Per guest
28	Drinks Corkage** (Lotus&Desert Rose)	50	100	Juices, Soft Drinks, Ice, Water, Mixers; 1 Bar Tender, 2 Waiters, 2 Cleaners, 2 Security, 1 Hostess; Bar Equipment; Music Equip, Disposable Glasses	\N	t	Per guest
\.


--
-- Name: packages_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('packages_id_seq', 28, true);


--
-- Data for Name: payment; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY payment (id, invoice_id, type, user_id, value) FROM stdin;
\.


--
-- Name: payment_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('payment_id_seq', 1, false);


--
-- Data for Name: user; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY "user" (id, firstname, lastname, email, mobile, password, role, discount, status) FROM stdin;
22	Andrew	test	orion@new.com	123456789	$2a$06$oKPPbT3LJh9QVmzgKErWu.lRrYOJ8G/zagQ5PWLzG94tgXa3Ms6bC	manager	\N	t
23	Tomas	Moore	Misty33@gmail.com	323-471-0731 x02	$2a$06$HRvrVO3IagjrEHFlre0XmeMV1ygfUtLQi0rfFrD9eEsWZsGGu1JGy	user_role	0.09	t
24	Dion	O'Kon	Macy_Labadie@gmail.com	(948) 704-8288 x	$2a$06$E.WpY/eChhTwxwd2hJfXj.4RBtdU7u0oOpf5NUXjSw2UG8hPzzKO.	user_role	\N	t
25	Winfield	Batz	Walton.Cummings@yahoo.com	1-508-874-5425 x	$2a$06$uJKYfD.tQzXdwL1clVbd6OrrxUYwooayBDewMNzZgaJn/WMyLNXf6	user_role	\N	t
26	Uriel	Witting	Stella_Klocko@yahoo.com	1-951-422-7062	$2a$06$wqJO7zLTpAdK1mhD7Vn6vOlKyx1VxGpu9X6RRNy6hhc1GaA3WDAdG	user_role	0.09	t
27	Alex	Lev	alex64@new.com	123456789	$2a$06$IJRbIIi5Vty3V/7xb/GcsemdMBGHxf.LclxoQ/dgQd4OFaC6rvIsW	user_role	0.00	t
33	User	Name	test123@name.com	+111111111111	$2a$06$Vx6JWix3Y3if9sD.67snCOOHb47MiDhBuEqxyYvIzR8fV3djEj/q2	user_role	0.00	t
34	User	Name	test321@name.com	+111111111111	$2a$06$Bfvmdp6XInrNcoKmawzTM.B0DwEDpsJYJ0iLMIx19M8cLYDabJ6Le	user_role	0.00	t
36	User	Name	test213@name.com	+111111111111	$2a$06$0VvEoo51CIOFsb9p3BLRKuAXQoatczCKlRe6tuxZUR1q82Ul/yJsm	user_role	0.00	t
37	User	Name	test214@name.com	+111111111111	$2a$06$..X04ZgKg/LsOPl2syTb6OmjShFnl/93iEKRXXfCtyMtyX1td8DuS	user_role	0.00	t
38	User	Name	test215@name.com	+111111111111	$2a$06$GEDM2yjj4dtjxTLR3f7D8.DRXP7reZqVjJNE/gsmFxa23kGgoi/1y	user_role	0.00	t
39	User	Name	test216@name.com	+111111111111	$2a$06$bR8r5vCmeZXPfC/unl3Age625HsevZSkbtB8HvsIzTbKsVTdnIOkq	user_role	0.00	t
\.


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('user_id_seq', 39, true);


--
-- Data for Name: yacht; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY yacht (id, title, content, readmore, status) FROM stdin;
6	LOTUS 220	Festus planeta sapienter promissios nuclear vexatum iacere est. liberi, rumor, et lamia	220 Feet Long (67 Meter) & 46 Feet Wide (14 Meter), 4 Deck Levels\r\nTotal Deck Surface Area – 26,490 Sq. feet (2,500 Sq. Meters)\r\nCabin Area – 17,287 Sq. feet (1600 Sq. Meters)\r\n11 Guest Bedrooms – Master Suite 1200 sq. Feet with Sun roof and Glass balcony, 6 Crew en suite Bedrooms on Lower Deck. 30 Bathrooms,\r\nMultiple Large Saloons & Dining, Kitchen, Cold Rooms Dry Pantry, Laundry, Food Lift, passenger Lift, Automated Doors. Side Open automated Bulwarks. Hydraulic Canopy\r\nSwimming Pool 400 sq. feet Fresh Water 42,000 Liters temp Controlled. 1 x 10 person Large Jacuzzi, 5 Private Jacuzzi . SPA with Sauna , Steam Room, Changing Rooms\r\n70 seat Luxury Cinema with 400 Sq. Ft screen, 200 Person Night Club & dance Floor, with Professional Sound & Lighting System. Professional Audio Systems all across with additional 4 Theatres (150 Inch Screens), Total 20 + TV screens across the boat\r\nFully Equipped & Furnished with High end Furnishings & Equipment\r\nIpad controlled Intelligent Automated Yacht Management System with 1000 + Color Changing RGB Lights (Underwater , pool, deck and Interior)\r\nToy Garage with 2 Ton Davit, 18 feet High speed Seadoo Jet boat, 2 Yamaha Wave Runner Jet Ski and lots of Toys. \r\nAmple Air-conditioning for Middle East Weather\r\nLot of Accessories, Safety Equipment, Life Rafts , 1200 Life jackets, Chinaware, Toys \r\nFor parties accommodates up to 1000+ People including 400 Table settings. Multiple Bars\r\nSteel Double Hull and Double Bottom. 150,000 Liters of Water & Fuel Capacity\r\n4 Diesel Engines – 400 HP x 4; 3 Diesel Generators - 2 X 192 Kw + 1 x 50 Kw, 4 X 72 KW Thrusters. Rudder Joy stick steering system\r\n	t
7	DESERT ROSE 155	Musas sunt terrors de fidelis spatii. Hibridas sunt humani generiss de talis adiurator. 	155 Feet Long (47 Meter) & 28.5 Feet Wide (8.7 Meter), 4 Deck Levels\r\nTotal Deck Surface Area – 11,836 Sq. feet (1,100 Sq. Meters)\r\nCabin Area – 8,600 Sq. feet (800 Sq. Meters)\r\nFully Equipped & Furnished with High end Furnishings & Equipment\r\n14 Bedrooms – 6 VIP Bedrooms on Main Deck + 8 Bedrooms on Lower Deck\r\n18 Bathrooms, Large Saloon & Dining, Kitchen, Dry Pantry, Laundry\r\nFresh Water 17,000 Liter temp Controlled Swimming Pool\r\nDance Floor with Professional Sound & Lighting System\r\nIpad controlled Intelligent Automated Yacht Management System with 1000 + Color Changing RGB Lights (Underwater, pool, deck and Interior)\r\nProfessional Audio Systems all across with 2 Theatres (150 Inch Screens), Total 20 + TV screens across the boat\r\n2 Yamaha Wave Runner Jet Ski Areas with Davit\r\nAmple Air-conditioning for Middle East Weather\r\nLot of Accessories, Safety Equipment, Chinaware, Toys\r\nFor parties accommodates up to 350 People including 150 Table settings\r\nAluminum Double Hull and Double Bottom. 60,000 Liters of Fuel & water Capacity\r\n3 Diesel Engines: 440 HP X 1 + 2 x 400 HP ; 2 X 96 kw diesel generators ; 2 X 72 KW Thrusters. Joystick Steering\r\n	t
8	VIRGO 88	Pol, a bene idoleum, fidelis olla! Sunt heureteses promissio bassus, mirabilis contencioes. 	Water Line Length 80 Feet Long (24 Meter), 15 Feet Wide (4.7 Meter), 3 Deck Levels\r\nTotal Deck Surface Area – 2,100 Sq. feet (200 Sq. Meters)\r\nCabin Area – 807 Sq. feet (75 Sq. Meters)\r\nFully Equipped & Furnished with High end Furnishings & Equipment\r\n3 Bedrooms, 2 Salons , Galley , Crew Room, 4 Bathrooms\r\n8,000 Liter temp Controlled Pool\r\nProfessional Sound & Lighting System\r\nAutomated Color Changing RGB Underwater , pool, deck and Interior Lighting\r\nProfessional Audio Systems all across, 7 TV screens across the boat\r\n2 Yamaha Wave Runner Jet Ski Areas with Davit. \r\nAmple Air-conditioning for Middle East Weather\r\nLot of Accessories, Safety Equipment, Chinaware, Toys\r\nFor parties accommodates up to 60 People\r\nAluminum Double Hull and Double Bottom. 60,000 Liters of Fuel & water Capacity\r\nEngines 2 X 300 HP, 2 x 15 Kw Generators, Stern & Bow Thrusters, Electronic Joy Stick steering\r\n	t
9	KHAN 90	Sensorems ridetis, tanquam varius xiphias. Regius nutrix inciviliter tractares tata est. 	Particulas potus, tanquam secundus pulchritudine. Nuptia, tumultumque, et hibrida. A falsis, hydra domesticus demissio. Caniss mori, tanquam fortis nuclear vexatum iacere. Est pius vigil, cesaris. Cum idoleum crescere, omnes apolloniateses carpseris placidus, bi-color rectores.	t
10	PLUTO 75	Scutum, torquis, et sensorem. Bi-color, festus tumultumques una aperto de albus, grandis axona. 	Cum armarium peregrinatione, omnes nuclear vexatum iacerees locus brevis, pius gloses. Armariums assimilant in cubiculum! Buxum de azureus competition, promissio abnoba! Ubi est fortis axona? Mirabilis, fortis zirbuss solite convertam de superbus, altus plasmator.	t
\.


--
-- Name: yacht_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('yacht_id_seq', 10, true);


SET search_path = sqitch, pg_catalog;

--
-- Data for Name: changes; Type: TABLE DATA; Schema: sqitch; Owner: postgres
--

COPY changes (change_id, change, project, note, committed_at, committer_name, committer_email, planned_at, planner_name, planner_email) FROM stdin;
58691fcdbc0aa10b7dbc02b489515483d2f9522a	appschema	ymigration	Adding schemas	2016-12-02 14:37:04.48589+00	root	root@f1ecd19207f5	2016-11-18 16:28:29+00	Andriy Doroshenko	mapleukraine@gmail.com
8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	2016-12-02 14:37:04.674396+00	root	root@f1ecd19207f5	2016-11-24 16:49:31+00	root	root@e43b902571be
9779f1a28c8d5f34f6038ed9181368a428f7c366	modify_packages	ymigration	new database schema.	2016-12-02 18:13:26.793806+00	root	root@a4b58a7258ca	2016-12-02 16:02:29+00	root	root@081905fb7d15
6c444e6fd2993bb62c711c7443cf092f7f990852	appschema	ymigration	new database schema.	2016-12-02 18:13:28.38284+00	root	root@a4b58a7258ca	2016-12-02 16:13:31+00	root	root@081905fb7d15
d93dcb458ec2cb8c840fe9191478b205eb9957ec	v20161212	ymigration	next generation	2016-12-13 12:15:11.530441+00	root	root@37ee3a03f8ae	2016-12-12 13:54:53+00	root	root@be5f43b59dca
\.


--
-- Data for Name: dependencies; Type: TABLE DATA; Schema: sqitch; Owner: postgres
--

COPY dependencies (change_id, type, dependency, dependency_id) FROM stdin;
8e4446d32c71c12b51aff191112544b7a6a78a9d	require	appschema	58691fcdbc0aa10b7dbc02b489515483d2f9522a
9779f1a28c8d5f34f6038ed9181368a428f7c366	require	modify_packages@v1.0.0-dev4	8e4446d32c71c12b51aff191112544b7a6a78a9d
9779f1a28c8d5f34f6038ed9181368a428f7c366	require	appschema	58691fcdbc0aa10b7dbc02b489515483d2f9522a
6c444e6fd2993bb62c711c7443cf092f7f990852	require	appschema@v1.0.0-dev5	58691fcdbc0aa10b7dbc02b489515483d2f9522a
d93dcb458ec2cb8c840fe9191478b205eb9957ec	require	appschema	58691fcdbc0aa10b7dbc02b489515483d2f9522a
d93dcb458ec2cb8c840fe9191478b205eb9957ec	require	modify_packages	8e4446d32c71c12b51aff191112544b7a6a78a9d
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: sqitch; Owner: postgres
--

COPY events (event, change_id, change, project, note, requires, conflicts, tags, committed_at, committer_name, committer_email, planned_at, planner_name, planner_email) FROM stdin;
deploy	58691fcdbc0aa10b7dbc02b489515483d2f9522a	appschema	ymigration	Adding schemas	{}	{}	{@v1.0.0-dev1,@v1.0.0-dev2,@v1.0.0-dev3}	2016-12-02 14:37:04.492264+00	root	root@f1ecd19207f5	2016-11-18 16:28:29+00	Andriy Doroshenko	mapleukraine@gmail.com
deploy	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-12-02 14:37:04.677884+00	root	root@f1ecd19207f5	2016-11-24 16:49:31+00	root	root@e43b902571be
deploy	9779f1a28c8d5f34f6038ed9181368a428f7c366	modify_packages	ymigration	new database schema.	{modify_packages@v1.0.0-dev4,appschema}	{}	{@v1.0.0-dev5}	2016-12-02 18:13:26.79927+00	root	root@a4b58a7258ca	2016-12-02 16:02:29+00	root	root@081905fb7d15
deploy	6c444e6fd2993bb62c711c7443cf092f7f990852	appschema	ymigration	new database schema.	{appschema@v1.0.0-dev5}	{}	{@v1.0.0-dev6}	2016-12-02 18:13:28.387051+00	root	root@a4b58a7258ca	2016-12-02 16:13:31+00	root	root@081905fb7d15
deploy	d93dcb458ec2cb8c840fe9191478b205eb9957ec	v20161212	ymigration	next generation	{appschema,modify_packages}	{}	{}	2016-12-13 12:15:11.585666+00	root	root@37ee3a03f8ae	2016-12-12 13:54:53+00	root	root@be5f43b59dca
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: sqitch; Owner: postgres
--

COPY projects (project, uri, created_at, creator_name, creator_email) FROM stdin;
ymigration	\N	2016-12-02 14:37:02.831958+00	root	root@f1ecd19207f5
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: sqitch; Owner: postgres
--

COPY tags (tag_id, tag, project, change_id, note, committed_at, committer_name, committer_email, planned_at, planner_name, planner_email) FROM stdin;
a824ddc9d1fed07d6337e85108a17b1381b32bee	@v1.0.0-dev1	ymigration	58691fcdbc0aa10b7dbc02b489515483d2f9522a	Tag v1.0.0-dev1.	2016-12-02 14:37:04.489255+00	root	root@f1ecd19207f5	2016-11-21 13:28:20+00	root	root@4003b84b92ac
333e8b66e64c7846d53a00c49442d9339d316310	@v1.0.0-dev2	ymigration	58691fcdbc0aa10b7dbc02b489515483d2f9522a	Tag v1.0.0-dev2	2016-12-02 14:37:04.489571+00	root	root@f1ecd19207f5	2016-11-21 19:09:00+00	root	root@c2f4bd2506a1
dff7b49b899caebf1f82414e1d1d3691048aa96f	@v1.0.0-dev3	ymigration	58691fcdbc0aa10b7dbc02b489515483d2f9522a	Tag v1.0.0-dev3	2016-12-02 14:37:04.4896+00	root	root@f1ecd19207f5	2016-11-24 12:45:00+00	root	root@e43b902571be
78e257e51c9ff7278485efdff192246e028af869	@v1.0.0-dev4	ymigration	8e4446d32c71c12b51aff191112544b7a6a78a9d	Tag v1.0.0-dev4.	2016-12-02 18:13:26.249572+00	root	root@a4b58a7258ca	2016-12-02 15:57:58+00	root	root@081905fb7d15
de722fcd48c391c618444d5dd081274826723b97	@v1.0.0-dev5	ymigration	9779f1a28c8d5f34f6038ed9181368a428f7c366	Tag v1.0.0-dev5.	2016-12-02 18:13:26.797302+00	root	root@a4b58a7258ca	2016-12-02 16:12:15+00	root	root@081905fb7d15
514fcc72e9f16f8a77f17ce261ab514940ef1305	@v1.0.0-dev6	ymigration	6c444e6fd2993bb62c711c7443cf092f7f990852	Tag v1.0.0-dev6.	2016-12-02 18:13:28.38543+00	root	root@a4b58a7258ca	2016-12-02 16:22:12+00	root	root@081905fb7d15
\.


SET search_path = auth, pg_catalog;

--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (token);


SET search_path = my_yacht, pg_catalog;

--
-- Name: additional pk_id_additional; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY additional
    ADD CONSTRAINT pk_id_additional PRIMARY KEY (id);


--
-- Name: booking pk_id_booking; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY booking
    ADD CONSTRAINT pk_id_booking PRIMARY KEY (id);


--
-- Name: devices pk_id_devices; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY devices
    ADD CONSTRAINT pk_id_devices PRIMARY KEY (id);


--
-- Name: download pk_id_download; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY download
    ADD CONSTRAINT pk_id_download PRIMARY KEY (id);


--
-- Name: extras pk_id_extras; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY extras
    ADD CONSTRAINT pk_id_extras PRIMARY KEY (id);


--
-- Name: file pk_id_file; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY file
    ADD CONSTRAINT pk_id_file PRIMARY KEY (id);


--
-- Name: invoice pk_id_invoice; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY invoice
    ADD CONSTRAINT pk_id_invoice PRIMARY KEY (id);


--
-- Name: packages pk_id_packages; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY packages
    ADD CONSTRAINT pk_id_packages PRIMARY KEY (id);


--
-- Name: payment pk_id_payment; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY payment
    ADD CONSTRAINT pk_id_payment PRIMARY KEY (id);


--
-- Name: user pk_id_yacht; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT pk_id_yacht PRIMARY KEY (id);


--
-- Name: yacht pr_id_yacht; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY yacht
    ADD CONSTRAINT pr_id_yacht PRIMARY KEY (id);


--
-- Name: user unq_email; Type: CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY "user"
    ADD CONSTRAINT unq_email UNIQUE (email);


SET search_path = sqitch, pg_catalog;

--
-- Name: changes changes_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY changes
    ADD CONSTRAINT changes_pkey PRIMARY KEY (change_id);


--
-- Name: dependencies dependencies_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY dependencies
    ADD CONSTRAINT dependencies_pkey PRIMARY KEY (change_id, dependency);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_pkey PRIMARY KEY (change_id, committed_at);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project);


--
-- Name: projects projects_uri_key; Type: CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_uri_key UNIQUE (uri);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (tag_id);


--
-- Name: tags tags_project_tag_key; Type: CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_project_tag_key UNIQUE (project, tag);


SET search_path = my_yacht, pg_catalog;

--
-- Name: user encrypt_pass; Type: TRIGGER; Schema: my_yacht; Owner: postgres
--

CREATE TRIGGER encrypt_pass BEFORE INSERT OR UPDATE ON "user" FOR EACH ROW EXECUTE PROCEDURE auth.encrypt_pass();


--
-- Name: users update_users; Type: TRIGGER; Schema: my_yacht; Owner: postgres
--

CREATE TRIGGER update_users INSTEAD OF INSERT OR DELETE OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_users();


SET search_path = auth, pg_catalog;

--
-- Name: tokens tokens_email_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: postgres
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_email_fkey FOREIGN KEY (email) REFERENCES my_yacht."user"(email) ON UPDATE CASCADE ON DELETE CASCADE;


SET search_path = my_yacht, pg_catalog;

--
-- Name: additional fk_additional_booking; Type: FK CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY additional
    ADD CONSTRAINT fk_additional_booking FOREIGN KEY (booking_id) REFERENCES booking(id);


--
-- Name: additional fk_additional_extras; Type: FK CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY additional
    ADD CONSTRAINT fk_additional_extras FOREIGN KEY (extras_id) REFERENCES extras(id);


--
-- Name: additional fk_additional_packages; Type: FK CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY additional
    ADD CONSTRAINT fk_additional_packages FOREIGN KEY (packages_id) REFERENCES packages(id);


--
-- Name: booking fk_booking_user; Type: FK CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY booking
    ADD CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES "user"(id);


--
-- Name: booking fk_booking_yacht; Type: FK CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY booking
    ADD CONSTRAINT fk_booking_yacht FOREIGN KEY (y_id) REFERENCES yacht(id);


--
-- Name: file fk_file_yacht; Type: FK CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY file
    ADD CONSTRAINT fk_file_yacht FOREIGN KEY (y_id) REFERENCES yacht(id);


--
-- Name: invoice fk_invoice_booking; Type: FK CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY invoice
    ADD CONSTRAINT fk_invoice_booking FOREIGN KEY (booking_id) REFERENCES booking(id);


--
-- Name: payment fk_payment_invoice; Type: FK CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY payment
    ADD CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES invoice(id);


--
-- Name: payment fk_payment_user; Type: FK CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY payment
    ADD CONSTRAINT fk_payment_user FOREIGN KEY (user_id) REFERENCES "user"(id);


SET search_path = sqitch, pg_catalog;

--
-- Name: changes changes_project_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY changes
    ADD CONSTRAINT changes_project_fkey FOREIGN KEY (project) REFERENCES projects(project) ON UPDATE CASCADE;


--
-- Name: dependencies dependencies_change_id_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY dependencies
    ADD CONSTRAINT dependencies_change_id_fkey FOREIGN KEY (change_id) REFERENCES changes(change_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: dependencies dependencies_dependency_id_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY dependencies
    ADD CONSTRAINT dependencies_dependency_id_fkey FOREIGN KEY (dependency_id) REFERENCES changes(change_id) ON UPDATE CASCADE;


--
-- Name: events events_project_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY events
    ADD CONSTRAINT events_project_fkey FOREIGN KEY (project) REFERENCES projects(project) ON UPDATE CASCADE;


--
-- Name: tags tags_change_id_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_change_id_fkey FOREIGN KEY (change_id) REFERENCES changes(change_id) ON UPDATE CASCADE;


--
-- Name: tags tags_project_fkey; Type: FK CONSTRAINT; Schema: sqitch; Owner: postgres
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_project_fkey FOREIGN KEY (project) REFERENCES projects(project) ON UPDATE CASCADE;


--
-- Name: auth; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA auth TO guest;
GRANT USAGE ON SCHEMA auth TO manager;
GRANT USAGE ON SCHEMA auth TO user_role;


--
-- Name: my_yacht; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA my_yacht TO guest;
GRANT USAGE ON SCHEMA my_yacht TO manager;
GRANT USAGE ON SCHEMA my_yacht TO user_role;


SET search_path = my_yacht, pg_catalog;

--
-- Name: login(text, text); Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON FUNCTION login(email text, password text) TO guest;
GRANT ALL ON FUNCTION login(email text, password text) TO manager;
GRANT ALL ON FUNCTION login(email text, password text) TO user_role;


--
-- Name: request_password_reset(text); Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON FUNCTION request_password_reset(email text) TO manager;
GRANT ALL ON FUNCTION request_password_reset(email text) TO user_role;


--
-- Name: reset_password(text, uuid, text); Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON FUNCTION reset_password(email text, token uuid, password text) TO manager;
GRANT ALL ON FUNCTION reset_password(email text, token uuid, password text) TO user_role;


--
-- Name: signup(text, text, text, text, text); Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON FUNCTION signup(firstname text, lastname text, email text, mobile text, password text) TO guest;


--
-- Name: update_users(); Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON FUNCTION update_users() TO guest;


SET search_path = public, pg_catalog;

--
-- Name: request_password_reset(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION request_password_reset(email text) TO manager;


--
-- Name: reset_password(text, uuid, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION reset_password(email text, token uuid, pass text) TO manager;


--
-- Name: signup(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION signup(email text, pass text) TO manager;


SET search_path = auth, pg_catalog;

--
-- Name: tokens; Type: ACL; Schema: auth; Owner: postgres
--

GRANT INSERT ON TABLE tokens TO guest;


SET search_path = my_yacht, pg_catalog;

--
-- Name: additional; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE additional TO manager;
GRANT INSERT ON TABLE additional TO guest;
GRANT SELECT,INSERT ON TABLE additional TO user_role;


--
-- Name: additional_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE additional_id_seq TO guest;


--
-- Name: booking; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT,INSERT,UPDATE ON TABLE booking TO manager;
GRANT INSERT ON TABLE booking TO guest;
GRANT SELECT,INSERT ON TABLE booking TO user_role;


--
-- Name: booking_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE booking_id_seq TO guest;


--
-- Name: devices_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE devices_id_seq TO guest;


--
-- Name: download; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE download TO user_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE download TO manager;
GRANT SELECT ON TABLE download TO guest;


--
-- Name: download_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE download_id_seq TO guest;


--
-- Name: extras; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE extras TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE extras TO manager;
GRANT SELECT ON TABLE extras TO guest;


--
-- Name: extras_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE extras_id_seq TO guest;


--
-- Name: file; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE file TO user_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE file TO manager;
GRANT SELECT ON TABLE file TO guest;


--
-- Name: file_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE file_id_seq TO guest;


--
-- Name: invoice; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE invoice TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE invoice TO manager;


--
-- Name: invoice_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE invoice_id_seq TO guest;


--
-- Name: packages; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE packages TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE packages TO manager;
GRANT SELECT ON TABLE packages TO guest;


--
-- Name: packages_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE packages_id_seq TO guest;


--
-- Name: payment_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE payment_id_seq TO guest;


--
-- Name: user; Type: ACL; Schema: my_yacht; Owner: postgres
--

REVOKE ALL ON TABLE "user" FROM postgres;
GRANT SELECT,UPDATE ON TABLE "user" TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE "user" TO manager;


--
-- Name: user_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE user_id_seq TO guest;


--
-- Name: users; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,UPDATE ON TABLE users TO manager;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,UPDATE ON TABLE users TO user_role;
GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,UPDATE ON TABLE users TO guest;


--
-- Name: yacht; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE yacht TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE yacht TO manager;
GRANT SELECT ON TABLE yacht TO guest;


--
-- Name: yacht_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE yacht_id_seq TO guest;


SET search_path = pg_catalog;

--
-- Name: pg_authid; Type: ACL; Schema: pg_catalog; Owner: postgres
--

GRANT SELECT ON TABLE pg_authid TO manager;
GRANT SELECT ON TABLE pg_authid TO user_role;
GRANT SELECT ON TABLE pg_authid TO guest;


--
-- PostgreSQL database dump complete
--
