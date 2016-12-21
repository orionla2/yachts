-- Deploy t_packages
-- requires: types

BEGIN;

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
ALTER TABLE ONLY packages ALTER COLUMN id SET DEFAULT nextval('packages_id_seq'::regclass);
ALTER TABLE ONLY packages
    ADD CONSTRAINT pk_id_packages PRIMARY KEY (id);

GRANT SELECT ON TABLE packages TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE packages TO manager;
GRANT SELECT ON TABLE packages TO guest;


--
-- Name: packages_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE packages_id_seq TO guest;



COMMIT;
