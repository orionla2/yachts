--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.0
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
  return result;
end;
$$;


ALTER FUNCTION my_yacht.login(email text, password text) OWNER TO postgres;

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
    LANGUAGE sql
    AS $$
  insert into my_yacht.users (firstname, lastname, email, mobile, password,role, discount) values
    (signup.firstname, signup.lastname, signup.email, signup.mobile, signup.password, 'user_role', '0');
$$;


ALTER FUNCTION my_yacht.signup(firstname text, lastname text, email text, mobile text, password text) OWNER TO postgres;

--
-- Name: update_users(); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--

CREATE FUNCTION update_users() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if tg_op = 'INSERT' then
    perform auth.clearance_for_role(new.role);

    insert into my_yacht.user
      (firstname,lastname,email,mobile,password,role,discount)
    values
      (new.firstname, new.lastname, new.email, new.mobile, new.password, new.role,new.discount);
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
    money money
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
    payment money,
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
    price money NOT NULL,
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
    rate money NOT NULL,
    subtotal money NOT NULL,
    total money,
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
    price money NOT NULL,
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
    value money
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


SET search_path = public, pg_catalog;

--
-- Name: num_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE num_users (
    count bigint
);


ALTER TABLE num_users OWNER TO postgres;

SET search_path = sqitch, pg_catalog;

--
-- Name: changes; Type: TABLE; Schema: sqitch; Owner: postgres
--

CREATE TABLE changes (
    change_id text NOT NULL,
    change text NOT NULL,
    project text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    committed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    committer_name text NOT NULL,
    committer_email text NOT NULL,
    planned_at timestamp with time zone NOT NULL,
    planner_name text NOT NULL,
    planner_email text NOT NULL
);


ALTER TABLE changes OWNER TO postgres;

--
-- Name: TABLE changes; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON TABLE changes IS 'Tracks the changes currently deployed to the database.';


--
-- Name: COLUMN changes.change_id; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN changes.change_id IS 'Change primary key.';


--
-- Name: COLUMN changes.change; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN changes.change IS 'Name of a deployed change.';


--
-- Name: COLUMN changes.project; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN changes.project IS 'Name of the Sqitch project to which the change belongs.';


--
-- Name: COLUMN changes.note; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN changes.note IS 'Description of the change.';


--
-- Name: COLUMN changes.committed_at; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN changes.committed_at IS 'Date the change was deployed.';


--
-- Name: COLUMN changes.committer_name; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN changes.committer_name IS 'Name of the user who deployed the change.';


--
-- Name: COLUMN changes.committer_email; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN changes.committer_email IS 'Email address of the user who deployed the change.';


--
-- Name: COLUMN changes.planned_at; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN changes.planned_at IS 'Date the change was added to the plan.';


--
-- Name: COLUMN changes.planner_name; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN changes.planner_name IS 'Name of the user who planed the change.';


--
-- Name: COLUMN changes.planner_email; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN changes.planner_email IS 'Email address of the user who planned the change.';


--
-- Name: dependencies; Type: TABLE; Schema: sqitch; Owner: postgres
--

CREATE TABLE dependencies (
    change_id text NOT NULL,
    type text NOT NULL,
    dependency text NOT NULL,
    dependency_id text,
    CONSTRAINT dependencies_check CHECK ((((type = 'require'::text) AND (dependency_id IS NOT NULL)) OR ((type = 'conflict'::text) AND (dependency_id IS NULL))))
);


ALTER TABLE dependencies OWNER TO postgres;

--
-- Name: TABLE dependencies; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON TABLE dependencies IS 'Tracks the currently satisfied dependencies.';


--
-- Name: COLUMN dependencies.change_id; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN dependencies.change_id IS 'ID of the depending change.';


--
-- Name: COLUMN dependencies.type; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN dependencies.type IS 'Type of dependency.';


--
-- Name: COLUMN dependencies.dependency; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN dependencies.dependency IS 'Dependency name.';


--
-- Name: COLUMN dependencies.dependency_id; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN dependencies.dependency_id IS 'Change ID the dependency resolves to.';


--
-- Name: events; Type: TABLE; Schema: sqitch; Owner: postgres
--

CREATE TABLE events (
    event text NOT NULL,
    change_id text NOT NULL,
    change text NOT NULL,
    project text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    requires text[] DEFAULT '{}'::text[] NOT NULL,
    conflicts text[] DEFAULT '{}'::text[] NOT NULL,
    tags text[] DEFAULT '{}'::text[] NOT NULL,
    committed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    committer_name text NOT NULL,
    committer_email text NOT NULL,
    planned_at timestamp with time zone NOT NULL,
    planner_name text NOT NULL,
    planner_email text NOT NULL,
    CONSTRAINT events_event_check CHECK ((event = ANY (ARRAY['deploy'::text, 'revert'::text, 'fail'::text])))
);


ALTER TABLE events OWNER TO postgres;

--
-- Name: TABLE events; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON TABLE events IS 'Contains full history of all deployment events.';


--
-- Name: COLUMN events.event; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.event IS 'Type of event.';


--
-- Name: COLUMN events.change_id; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.change_id IS 'Change ID.';


--
-- Name: COLUMN events.change; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.change IS 'Change name.';


--
-- Name: COLUMN events.project; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.project IS 'Name of the Sqitch project to which the change belongs.';


--
-- Name: COLUMN events.note; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.note IS 'Description of the change.';


--
-- Name: COLUMN events.requires; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.requires IS 'Array of the names of required changes.';


--
-- Name: COLUMN events.conflicts; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.conflicts IS 'Array of the names of conflicting changes.';


--
-- Name: COLUMN events.tags; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.tags IS 'Tags associated with the change.';


--
-- Name: COLUMN events.committed_at; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.committed_at IS 'Date the event was committed.';


--
-- Name: COLUMN events.committer_name; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.committer_name IS 'Name of the user who committed the event.';


--
-- Name: COLUMN events.committer_email; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.committer_email IS 'Email address of the user who committed the event.';


--
-- Name: COLUMN events.planned_at; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.planned_at IS 'Date the event was added to the plan.';


--
-- Name: COLUMN events.planner_name; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.planner_name IS 'Name of the user who planed the change.';


--
-- Name: COLUMN events.planner_email; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN events.planner_email IS 'Email address of the user who plan planned the change.';


--
-- Name: projects; Type: TABLE; Schema: sqitch; Owner: postgres
--

CREATE TABLE projects (
    project text NOT NULL,
    uri text,
    created_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    creator_name text NOT NULL,
    creator_email text NOT NULL
);


ALTER TABLE projects OWNER TO postgres;

--
-- Name: TABLE projects; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON TABLE projects IS 'Sqitch projects deployed to this database.';


--
-- Name: COLUMN projects.project; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN projects.project IS 'Unique Name of a project.';


--
-- Name: COLUMN projects.uri; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN projects.uri IS 'Optional project URI';


--
-- Name: COLUMN projects.created_at; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN projects.created_at IS 'Date the project was added to the database.';


--
-- Name: COLUMN projects.creator_name; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN projects.creator_name IS 'Name of the user who added the project.';


--
-- Name: COLUMN projects.creator_email; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN projects.creator_email IS 'Email address of the user who added the project.';


--
-- Name: tags; Type: TABLE; Schema: sqitch; Owner: postgres
--

CREATE TABLE tags (
    tag_id text NOT NULL,
    tag text NOT NULL,
    project text NOT NULL,
    change_id text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    committed_at timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    committer_name text NOT NULL,
    committer_email text NOT NULL,
    planned_at timestamp with time zone NOT NULL,
    planner_name text NOT NULL,
    planner_email text NOT NULL
);


ALTER TABLE tags OWNER TO postgres;

--
-- Name: TABLE tags; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON TABLE tags IS 'Tracks the tags currently applied to the database.';


--
-- Name: COLUMN tags.tag_id; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN tags.tag_id IS 'Tag primary key.';


--
-- Name: COLUMN tags.tag; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN tags.tag IS 'Project-unique tag name.';


--
-- Name: COLUMN tags.project; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN tags.project IS 'Name of the Sqitch project to which the tag belongs.';


--
-- Name: COLUMN tags.change_id; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN tags.change_id IS 'ID of last change deployed before the tag was applied.';


--
-- Name: COLUMN tags.note; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN tags.note IS 'Description of the tag.';


--
-- Name: COLUMN tags.committed_at; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN tags.committed_at IS 'Date the tag was applied to the database.';


--
-- Name: COLUMN tags.committer_name; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN tags.committer_name IS 'Name of the user who applied the tag.';


--
-- Name: COLUMN tags.committer_email; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN tags.committer_email IS 'Email address of the user who applied the tag.';


--
-- Name: COLUMN tags.planned_at; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN tags.planned_at IS 'Date the tag was added to the plan.';


--
-- Name: COLUMN tags.planner_name; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN tags.planner_name IS 'Name of the user who planed the tag.';


--
-- Name: COLUMN tags.planner_email; Type: COMMENT; Schema: sqitch; Owner: postgres
--

COMMENT ON COLUMN tags.planner_email IS 'Email address of the user who planned the tag.';


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
\.


--
-- Name: additional_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('additional_id_seq', 1, false);


--
-- Data for Name: booking; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY booking (id, y_id, start_date, end_date, user_id, payment, status, payment_type, discount) FROM stdin;
\.


--
-- Name: booking_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('booking_id_seq', 1, false);


--
-- Data for Name: devices; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY devices (id, user_id, platform, device_id) FROM stdin;
1	19	Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_	Mozilla/5.0 (Windows; U; Windows NT 6.0) Appl
2	19	Mozilla/5.0 (compatible; MSIE 8.0; Windows NT	Mozilla/5.0 (Windows; U; Windows NT 5.3) Appl
3	19	Mozilla/5.0 (compatible; MSIE 8.0; Windows NT	Mozilla/5.0 (Windows; U; Windows NT 5.1) Appl
4	19	Mozilla/5.0 (Windows; U; Windows NT 5.1) Appl	Mozilla/5.0 (Windows; U; Windows NT 6.1) Appl
5	20	Mozilla/5.0 (Windows; U; Windows NT 5.0) Appl	Mozilla/5.0 (Windows; U; Windows NT 5.3) Appl
6	20	Mozilla/5.0 (Windows; U; Windows NT 6.0) Appl	Mozilla/5.0 (Windows NT 6.1; Trident/7.0; Tou
7	19	Mozilla/5.0 (Windows; U; Windows NT 5.1) Appl	Mozilla/5.0 (X11; Linux x86_64; rv:12.9) Geck
8	23	Mozilla/5.0 (compatible; MSIE 7.0; Windows NT	Mozilla/5.0 (Windows; U; Windows NT 6.2) Appl
9	19	Mozilla/5.0 (compatible; MSIE 9.0; Windows NT	Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.
10	19	Mozilla/5.0 (Windows; U; Windows NT 5.2) Appl	Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:
\.


--
-- Name: devices_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('devices_id_seq', 10, true);


--
-- Data for Name: download; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY download (id, tagline, filename) FROM stdin;
\.


--
-- Name: download_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('download_id_seq', 1, false);


--
-- Data for Name: extras; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY extras (id, title, price, min_charge, unit, description, status) FROM stdin;
1	Jet Boat	$500.00	1	Per Trip / Hour	Upto 7 People	t
2	Bar Man	$150.00	4	Per Hour	Professional Barman	t
3	Waiters / Staff	$75.00	4	Per Hour	Professional Waiters	t
4	Security/Bouncers	$100.00	4	Per Hour	VIP Background Security	t
5	Hostess	$150.00	4	Per Hour	Presentable & Professional	t
6	Photographer	$500.00	4	Per Hour	Standard Photographer	t
7	DJ	$500.00	4	Per Hour	House DJs, Excludes equipment	t
8	Professional Music equipment	$100.00	0	Per Event	CDJ(Pioneer R1), 4 Speaker+Sub, Mic	t
9	Theme/ Decorations	$0.00	0	Per Event	As Per Actual + 25% Surcharge	t
\.


--
-- Name: extras_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('extras_id_seq', 9, true);


--
-- Data for Name: file; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY file (id, type, url, y_id) FROM stdin;
1	description	http://lorempixel.com/640/480/transport	2
2	description	http://lorempixel.com/640/480/transport	6
3	description	http://lorempixel.com/640/480/transport	2
4	description	http://lorempixel.com/640/480/transport	2
5	description	http://lorempixel.com/640/480/transport	5
6	drawing	http://lorempixel.com/640/480/transport	6
7	description	http://lorempixel.com/640/480/transport	5
8	image	http://lorempixel.com/640/480/transport	6
9	description	http://lorempixel.com/640/480/transport	5
10	description	http://lorempixel.com/640/480/transport	5
\.


--
-- Name: file_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('file_id_seq', 10, true);


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
1	Charter LOTUS 220	$10,000.00	4	Charter LOTUS 220	5	t	Hours
2	Charter DESERT ROSE 155	$5,000.00	4	Charter DESERT ROSE 155	2	t	Hours
3	Charter VIRGO 88	$2,000.00	4	Charter VIRGO 88	5	t	Hours
4	Charter KHAN 90	$2,000.00	4	Charter KHAN 90	5	t	Hours
5	Charter PLUTO 75	$1,250.00	4	Charter PLUTO 75	4	t	Hours
6	Premium Package (Meal+Drinks)	$395.00	50	5* Catered Premium Buffet + Live Station; Unlimited Premium Drinks for 4 Hours; Soft Drinks, Juices & Mixers; Bar Tender, Staff & Security; Security & Hostess; DJ, Music equip, Table Setting; 5* Hotel Staff	3	t	Guests
7	Standard Package (Meal+Drinks)	$295.00	50	5* Catered Standard Buffet + Live Station; Unlimited Standard Drinks for 4 Hours; Soft Drinks, Juices & Mixers; Bar Tender, Staff & Security; Security; Table Setting; 5* Hotel Staff	2	t	Guests
8	Drinks Premium	$245.00	50	Unlimited Premium Drinks for 4 Hours; Bar Tender, Staff & Security; Mixers, Juices & Soft Drinks; Packaged Snacks; Hostess, DJ & Music Equip	4	t	Guests
9	Drinks Standard	$145.00	50	Unlimited Standard Drinks for 4 Hours; Bar Tender, Staff & Security; Mixers, Juices & Soft Drinks	3	t	Guests
10	Buffet Meal Premium	$245.00	50	5* Catered Premium Buffet + Live Station & Soft Drinks; Table Setting; 5* Hotel Staff; Hostess; Music Equip	5	t	Guests
11	Buffet Meal Standard	$145.00	50	5* Catered Standard Buffet & Soft Drinks; Table Setting; 5* Hotel Staff	6	t	Guests
12	Soft Drinks	$25.00	100	Unlimited Soft Drinks, Juices, Water & Ice; 2 Waiters, 2 Cleaners	4	t	Guests
13	Catering Corkage (Lotus&Desert Rose)	$50.00	100	4 Helpers/Cleaners; 2Hrs Setup time + 1 Hour Cleaning time	4	t	Guests
14	Drinks Corkage** (Lotus&Desert Rose)	$50.00	100	Juices, Soft Drinks, Ice, Water, Mixers; 1 Bar Tender, 2 Waiters, 2 Cleaners, 2 Security, 1 Hostess; Bar Equipment; Music Equip, Disposable Glasses	4	t	Guests
\.


--
-- Name: packages_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('packages_id_seq', 14, true);


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
19	Andrew	test	orion@new.com	123456789	$2a$06$R9BKqVgd0g3z1SbvUEUGne8ShD48u.4Io39XL1.e.FGiqxLlhk3Qa	manager	\N	t
20	Macey	Schoen	Gideon.Kreiger89@gmail.com	040.406.4568 x23	$2a$06$tK3ZKYdoj.UF81ci5.W12uJ5yefxiWepqZSJMgeWQ6gw3K8ddAiJ6	user_role	0.04	t
21	Lexi	Murphy	Ramona40@hotmail.com	274.178.0358 x36	$2a$06$KYo7iN0gb4XN3Lw.nXrQG.gAYEphaRraiESLdRtm6LkKT4nOGFfOu	user_role	0.05	t
22	Connor	Langosh	Loy.Rodriguez@gmail.com	(274) 163-1196 x	$2a$06$BhUoqGpA.1WAxjkgfQW4nuPIZOAIeEEkj3Ts0ixJvq3g6b4uLLzpa	user_role	0.02	t
23	Irma	Hettinger	Mariano.Mueller@gmail.com	617-942-6350	$2a$06$DguIVdah.FLHxOsAtx17qeLkJc3hhba9CTYQFfn4O.0tVZHNoCZrC	user_role	\N	t
\.


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('user_id_seq', 23, true);


--
-- Data for Name: yacht; Type: TABLE DATA; Schema: my_yacht; Owner: postgres
--

COPY yacht (id, title, content, readmore, status) FROM stdin;
2	LOTUS 220	Festus planeta sapienter promissios nuclear vexatum iacere est. liberi, rumor, et lamia	Dura studeres, tanquam dexter orexis. brabeutas studere in varius rugensis civitas! burguss observare, tanquam lotus abactor. velum mechanice ducunt ad barbatus diatria. cottas manducare, tanquam gratis hilotae. cum coordinatae volare, omnes voxes acquirere azureus, audax ollaes. 	t
3	DESERT ROSE 155	Musas sunt terrors de fidelis spatii. Hibridas sunt humani generiss de talis adiurator. 	Heu, castus navis! Regius, rusticus solitudos solite pugna de grandis, brevis nomen. Ubi est bi-color brabeuta? A falsis, boreas clemens cotta. Sunt repressores captis salvus, regius fluctuses. Cum buxum volare, omnes hippotoxotaes gratia placidus, gratis coordinataees.	t
4	VIRGO 88	Pol, a bene idoleum, fidelis olla! Sunt heureteses promissio bassus, mirabilis contencioes. 	Hercle, solitudo emeritis!, rector! Planetas messis in tectum! Hercle, solem gratis!, alter demissio! Est domesticus fluctui, cesaris. Mineraliss volare in berolinum! Elevatuss nocere in copinga! Cum onus ire, omnes indictioes manifestum teres, nobilis fugaes.	t
5	KHAN 90	Sensorems ridetis, tanquam varius xiphias. Regius nutrix inciviliter tractares tata est. 	Particulas potus, tanquam secundus pulchritudine. Nuptia, tumultumque, et hibrida. A falsis, hydra domesticus demissio. Caniss mori, tanquam fortis nuclear vexatum iacere. Est pius vigil, cesaris. Cum idoleum crescere, omnes apolloniateses carpseris placidus, bi-color rectores.	t
6	PLUTO 75	Scutum, torquis, et sensorem. Bi-color, festus tumultumques una aperto de albus, grandis axona. 	Cum armarium peregrinatione, omnes nuclear vexatum iacerees locus brevis, pius gloses. Armariums assimilant in cubiculum! Buxum de azureus competition, promissio abnoba! Ubi est fortis axona? Mirabilis, fortis zirbuss solite convertam de superbus, altus plasmator.	t
\.


--
-- Name: yacht_id_seq; Type: SEQUENCE SET; Schema: my_yacht; Owner: postgres
--

SELECT pg_catalog.setval('yacht_id_seq', 6, true);


SET search_path = public, pg_catalog;

--
-- Data for Name: num_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY num_users (count) FROM stdin;
0
\.


SET search_path = sqitch, pg_catalog;

--
-- Data for Name: changes; Type: TABLE DATA; Schema: sqitch; Owner: postgres
--

COPY changes (change_id, change, project, note, committed_at, committer_name, committer_email, planned_at, planner_name, planner_email) FROM stdin;
58691fcdbc0aa10b7dbc02b489515483d2f9522a	appschema	ymigration	Adding schemas	2016-11-21 18:21:01.110806+00	root	root@f1d227de8158	2016-11-18 16:28:29+00	Andriy Doroshenko	mapleukraine@gmail.com
\.


--
-- Data for Name: dependencies; Type: TABLE DATA; Schema: sqitch; Owner: postgres
--

COPY dependencies (change_id, type, dependency, dependency_id) FROM stdin;
\.


--
-- Data for Name: events; Type: TABLE DATA; Schema: sqitch; Owner: postgres
--

COPY events (event, change_id, change, project, note, requires, conflicts, tags, committed_at, committer_name, committer_email, planned_at, planner_name, planner_email) FROM stdin;
fail	58691fcdbc0aa10b7dbc02b489515483d2f9522a	appschema	ymigration	Adding schemas	{}	{}	{@v1.0.0-dev1}	2016-11-21 17:59:41.140091+00	root	root@f1d227de8158	2016-11-18 16:28:29+00	Andriy Doroshenko	mapleukraine@gmail.com
fail	58691fcdbc0aa10b7dbc02b489515483d2f9522a	appschema	ymigration	Adding schemas	{}	{}	{@v1.0.0-dev1}	2016-11-21 18:18:43.482102+00	root	root@f1d227de8158	2016-11-18 16:28:29+00	Andriy Doroshenko	mapleukraine@gmail.com
deploy	58691fcdbc0aa10b7dbc02b489515483d2f9522a	appschema	ymigration	Adding schemas	{}	{}	{@v1.0.0-dev1}	2016-11-21 18:21:01.116217+00	root	root@f1d227de8158	2016-11-18 16:28:29+00	Andriy Doroshenko	mapleukraine@gmail.com
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-25 12:57:52.045983+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-25 13:06:39.635022+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-25 13:14:57.351133+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-25 13:27:54.388968+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-26 11:13:00.215491+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-27 13:25:23.31506+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 12:10:47.617455+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 12:13:09.098266+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 14:19:26.420953+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 14:39:04.459384+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:00:08.264755+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:02:34.412098+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:20:29.905311+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:25:09.239204+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:33:19.088628+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:36:03.801934+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:37:37.766207+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:38:29.633252+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:40:51.330522+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:47:52.924716+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:52:17.302227+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:54:00.726152+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:58:27.279294+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 17:59:02.730247+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 18:13:28.151665+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 18:16:23.421109+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 18:25:08.769886+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 18:31:42.045884+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 18:34:00.566287+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-28 18:40:09.086301+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-29 13:45:55.41339+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-29 16:41:20.165319+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-29 19:09:56.604977+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 13:44:43.502974+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 15:12:38.415987+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 15:26:14.55983+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 15:27:56.890851+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 15:35:05.762511+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 15:38:24.55446+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 15:41:16.248473+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 15:42:42.423335+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 15:44:21.216184+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 17:14:49.690145+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 17:49:33.683704+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-11-30 17:52:41.134142+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-12-01 11:46:51.301131+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-12-01 12:16:46.672539+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-12-01 12:18:32.645972+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-12-01 12:18:58.094654+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-12-01 15:01:08.744231+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
fail	8e4446d32c71c12b51aff191112544b7a6a78a9d	modify_packages	ymigration	Adds unit column to packages	{appschema}	{}	{}	2016-12-01 15:32:18.329031+00	root	root@d55cae5034f9	2016-11-24 16:49:31+00	root	root@e43b902571be
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: sqitch; Owner: postgres
--

COPY projects (project, uri, created_at, creator_name, creator_email) FROM stdin;
ymigration	\N	2016-11-21 17:59:39.068766+00	root	root@f1d227de8158
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: sqitch; Owner: postgres
--

COPY tags (tag_id, tag, project, change_id, note, committed_at, committer_name, committer_email, planned_at, planner_name, planner_email) FROM stdin;
a824ddc9d1fed07d6337e85108a17b1381b32bee	@v1.0.0-dev1	ymigration	58691fcdbc0aa10b7dbc02b489515483d2f9522a	Tag v1.0.0-dev1.	2016-11-21 18:21:01.113595+00	root	root@f1d227de8158	2016-11-21 13:28:20+00	root	root@4003b84b92ac
333e8b66e64c7846d53a00c49442d9339d316310	@v1.0.0-dev2	ymigration	58691fcdbc0aa10b7dbc02b489515483d2f9522a	Tag v1.0.0-dev2	2016-11-23 11:20:08.524829+00	root	root@f1d227de8158	2016-11-21 19:09:00+00	root	root@c2f4bd2506a1
dff7b49b899caebf1f82414e1d1d3691048aa96f	@v1.0.0-dev3	ymigration	58691fcdbc0aa10b7dbc02b489515483d2f9522a	Tag v1.0.0-dev3	2016-11-24 13:51:44.705416+00	root	root@d55cae5034f9	2016-11-24 12:45:00+00	root	root@e43b902571be
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
GRANT USAGE ON SCHEMA auth TO user_role;
GRANT USAGE ON SCHEMA auth TO manager;


--
-- Name: my_yacht; Type: ACL; Schema: -; Owner: postgres
--

GRANT USAGE ON SCHEMA my_yacht TO guest;
GRANT USAGE ON SCHEMA my_yacht TO user_role;
GRANT USAGE ON SCHEMA my_yacht TO manager;


SET search_path = my_yacht, pg_catalog;

--
-- Name: login(text, text); Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON FUNCTION login(email text, password text) TO guest;
GRANT ALL ON FUNCTION login(email text, password text) TO user_role;
GRANT ALL ON FUNCTION login(email text, password text) TO manager;


--
-- Name: request_password_reset(text); Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON FUNCTION request_password_reset(email text) TO user_role;
GRANT ALL ON FUNCTION request_password_reset(email text) TO manager;


--
-- Name: reset_password(text, uuid, text); Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON FUNCTION reset_password(email text, token uuid, password text) TO user_role;
GRANT ALL ON FUNCTION reset_password(email text, token uuid, password text) TO manager;


--
-- Name: signup(text, text, text, text, text); Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON FUNCTION signup(firstname text, lastname text, email text, mobile text, password text) TO guest;


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

GRANT SELECT,INSERT ON TABLE additional TO user_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE additional TO manager;
GRANT INSERT ON TABLE additional TO guest;


--
-- Name: booking; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE booking TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE booking TO manager;
GRANT INSERT ON TABLE booking TO guest;


--
-- Name: download; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE download TO user_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE download TO manager;
GRANT SELECT ON TABLE download TO guest;


--
-- Name: extras; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE extras TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE extras TO manager;
GRANT SELECT ON TABLE extras TO guest;


--
-- Name: file; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE file TO user_role;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE file TO manager;
GRANT SELECT ON TABLE file TO guest;


--
-- Name: invoice; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE invoice TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE invoice TO manager;


--
-- Name: packages; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE packages TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE packages TO manager;
GRANT SELECT ON TABLE packages TO guest;


--
-- Name: user; Type: ACL; Schema: my_yacht; Owner: postgres
--

REVOKE ALL ON TABLE "user" FROM postgres;
GRANT SELECT,INSERT ON TABLE "user" TO guest;
GRANT SELECT,UPDATE ON TABLE "user" TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE "user" TO manager;


--
-- Name: yacht; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE yacht TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE yacht TO manager;
GRANT SELECT ON TABLE yacht TO guest;


SET search_path = pg_catalog;

--
-- Name: pg_authid; Type: ACL; Schema: pg_catalog; Owner: postgres
--

GRANT SELECT ON TABLE pg_authid TO user_role;
GRANT SELECT ON TABLE pg_authid TO manager;
GRANT SELECT ON TABLE pg_authid TO guest;


--
-- PostgreSQL database dump complete
--

