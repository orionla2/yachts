-- Deploy t_devices
-- requires: types

BEGIN;

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
ALTER TABLE ONLY devices ALTER COLUMN id SET DEFAULT nextval('devices_id_seq'::regclass);
ALTER TABLE ONLY devices
    ADD CONSTRAINT pk_id_devices PRIMARY KEY (id);

GRANT ALL ON SEQUENCE devices_id_seq TO guest;


COMMIT;
