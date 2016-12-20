-- Deploy t_additional
-- requires: types

BEGIN;

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
ALTER TABLE ONLY additional ALTER COLUMN id SET DEFAULT nextval('additional_id_seq'::regclass);
ALTER TABLE ONLY additional
    ADD CONSTRAINT pk_id_additional PRIMARY KEY (id);
ALTER TABLE ONLY additional
    ADD CONSTRAINT fk_additional_booking FOREIGN KEY (booking_id) REFERENCES booking(id);
ALTER TABLE ONLY additional
    ADD CONSTRAINT fk_additional_extras FOREIGN KEY (extras_id) REFERENCES extras(id);
ALTER TABLE ONLY additional
    ADD CONSTRAINT fk_additional_packages FOREIGN KEY (packages_id) REFERENCES packages(id);

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE additional TO manager;
GRANT INSERT ON TABLE additional TO guest;
GRANT SELECT,INSERT ON TABLE additional TO user_role;

GRANT ALL ON SEQUENCE additional_id_seq TO guest;



COMMIT;
