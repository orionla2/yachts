-- Deploy t_booking
-- requires: types

BEGIN;

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
    payment numeric(64,2),
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
ALTER TABLE ONLY booking ALTER COLUMN id SET DEFAULT nextval('booking_id_seq'::regclass);
ALTER TABLE ONLY booking
    ADD CONSTRAINT pk_id_booking PRIMARY KEY (id);
ALTER TABLE ONLY booking
    ADD CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES "user"(id);

ALTER TABLE ONLY booking
    ADD CONSTRAINT fk_booking_yacht FOREIGN KEY (y_id) REFERENCES yacht(id);

GRANT SELECT,INSERT,UPDATE ON TABLE booking TO manager;
GRANT INSERT ON TABLE booking TO guest;
GRANT SELECT,INSERT ON TABLE booking TO user_role;


--
-- Name: booking_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE booking_id_seq TO guest;



COMMIT;
