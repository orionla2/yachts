-- Deploy ymigration:v20161212 to pg
-- requires: appschema
-- requires: modify_packages

BEGIN;

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


-- ======================= copy this to other deploy ============================= ---
CREATE ROLE manager;
CREATE ROLE user_role;
CREATE ROLE guest;
CREATE ROLE authenticator LOGIN
ENCRYPTED PASSWORD 'md5b8d79b0dea1de1788ea7dd39fa0ec195'
NOSUPERUSER NOINHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
GRANT guest TO authenticator;
GRANT manager TO authenticator;
GRANT user_role TO authenticator;
-- ======================= /copy this to other deploy ============================ ---

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

CREATE FUNCTION user_role(ch_email text, password text) RETURNS name
LANGUAGE plpgsql
AS $$
declare
  _role text;
begin
  select role from my_yacht.user as u
  where u.email = user_role.ch_email and u.password = crypt(user_role.password, u.password) into _role;
  return _role;
end;
$$;


ALTER FUNCTION auth.user_role(ch_email text, password text) OWNER TO postgres;

SET search_path = my_yacht, pg_catalog;

--
-- Name: login(text, text); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--

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

CREATE FUNCTION signup(firstname text, lastname text, email text, mobile text, password text) RETURNS void
LANGUAGE plpgsql
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
    msg := id || '.manager.user.newUser.sms';
    SELECT pg_notify('messanger',msg) into msg;
    msg := id || '.manager.user.newUser.push';
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

SET search_path = public, pg_catalog;

--
-- Name: request_password_reset(text); Type: FUNCTION; Schema: public; Owner: postgres
--

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


ALTER FUNCTION public.request_password_reset(email text) OWNER TO postgres;

--
-- Name: reset_password(text, uuid, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION reset_password(email text, token uuid, pass text) RETURNS void
LANGUAGE plpgsql
AS $$
declare
  tok uuid;
begin
  if exists(select 1 from auth.tokens
  where tokens.email = reset_password.email
        and tokens.token = reset_password.token
        and token_type = 'reset') then
    update auth.users set pass=reset_password.pass
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


ALTER FUNCTION public.reset_password(email text, token uuid, pass text) OWNER TO postgres;

--
-- Name: signup(text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION signup(email text, pass text) RETURNS void
LANGUAGE sql
AS $$
insert into auth.users (email, pass, role) values
  (signup.email, signup.pass, 'hardcoded-role-here');
$$;


ALTER FUNCTION public.signup(email text, pass text) OWNER TO postgres;

--
-- Name: update_users(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_users() RETURNS trigger
LANGUAGE plpgsql
AS $$
begin
  if tg_op = 'INSERT' then
    perform auth.clearance_for_role(new.role);

    insert into auth.users
    (role, pass, email, verified)
    values
      (new.role, new.pass, new.email,
       coalesce(new.verified, false));
    return new;
  elsif tg_op = 'UPDATE' then
    -- no need to check clearance for old.role because
    -- an ineligible row would not have been available to update (http 404)
    perform auth.clearance_for_role(new.role);

    update auth.users set
      email  = new.email,
      role   = new.role,
      pass   = new.pass,
      verified = coalesce(new.verified, old.verified, false)
    where email = old.email;
    return new;
  elsif tg_op = 'DELETE' then
    -- no need to check clearance for old.role (see previous case)

    delete from auth.users
    where auth.email = old.email;
    return null;
  end if;
end
$$;


ALTER FUNCTION public.update_users() OWNER TO postgres;

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

CREATE TABLE booking (
  id integer NOT NULL,
  y_id integer NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
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


SET search_path = my_yacht, pg_catalog;

--
-- Data for Name: additional; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--


--
-- Name: additional_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('additional_id_seq', 1, false);


--
-- Data for Name: booking; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--



--
-- Name: booking_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('booking_id_seq', 1, false);


--
-- Data for Name: devices; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--



--
-- Name: devices_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('devices_id_seq', 10, true);


--
-- Data for Name: download; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--


--
-- Name: download_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('download_id_seq', 1, true);


--
-- Data for Name: extras; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

--
-- Name: extras_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('extras_id_seq', 9, true);


--
-- Data for Name: file; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

--
-- Name: file_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('file_id_seq', 10, true);


--
-- Data for Name: invoice; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

-- Name: invoice_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('invoice_id_seq', 1, false);


--
-- Data for Name: packages; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

--
-- Name: packages_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('packages_id_seq', 14, true);


--
-- Data for Name: payment; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

--
-- Name: payment_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('payment_id_seq', 1, false);


--
-- Data for Name: user; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('user_id_seq', 21, true);


--
-- Data for Name: yacht; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

--
-- Name: yacht_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('yacht_id_seq', 5, true);


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


--
-- Name: auth; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA auth TO manager;
GRANT USAGE ON SCHEMA auth TO user_role;
GRANT USAGE ON SCHEMA auth TO guest;


--
-- Name: my_yacht; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA my_yacht TO manager;
GRANT USAGE ON SCHEMA my_yacht TO user_role;
GRANT USAGE ON SCHEMA my_yacht TO guest;


SET search_path = my_yacht, pg_catalog;

--
-- Name: login(text, text); Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON FUNCTION login(email text, password text) TO manager;
GRANT ALL ON FUNCTION login(email text, password text) TO user_role;
GRANT ALL ON FUNCTION login(email text, password text) TO guest;


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
GRANT SELECT,INSERT ON TABLE "user" TO guest;


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

GRANT SELECT ON TABLE pg_authid TO user_role;
GRANT SELECT ON TABLE pg_authid TO guest;
GRANT SELECT ON TABLE pg_authid TO manager;


--
-- PostgreSQL database dump complete
--



COMMIT;
