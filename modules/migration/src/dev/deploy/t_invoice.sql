-- Deploy t_invoice
-- requires: types

BEGIN;

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
    subtotal numeric(64,2) NOT NULL,
    total numeric(64,2),
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
ALTER TABLE ONLY invoice ALTER COLUMN id SET DEFAULT nextval('invoice_id_seq'::regclass);
ALTER TABLE ONLY invoice
    ADD CONSTRAINT pk_id_invoice PRIMARY KEY (id);

ALTER TABLE ONLY invoice
    ADD CONSTRAINT fk_invoice_booking FOREIGN KEY (booking_id) REFERENCES booking(id);
--
-- Name: invoice; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT SELECT ON TABLE invoice TO user_role;
GRANT SELECT,INSERT,UPDATE ON TABLE invoice TO manager;


--
-- Name: invoice_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE invoice_id_seq TO guest;


COMMIT;
