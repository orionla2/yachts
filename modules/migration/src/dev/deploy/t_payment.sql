-- Deploy t_payment
-- requires: types

BEGIN;

--
-- Name: payment; Type: TABLE; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
SET default_tablespace = '';
SET default_with_oids = false;
CREATE TABLE payment (
    id integer NOT NULL,
    invoice_id integer NOT NULL,
    type character varying(80) NOT NULL,
    user_id integer NOT NULL,
    value numeric(64,2)
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
ALTER TABLE ONLY payment ALTER COLUMN id SET DEFAULT nextval('payment_id_seq'::regclass);
ALTER TABLE ONLY payment
    ADD CONSTRAINT pk_id_payment PRIMARY KEY (id);
ALTER TABLE ONLY payment
    ADD CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES invoice(id);


--
-- Name: payment fk_payment_user; Type: FK CONSTRAINT; Schema: my_yacht; Owner: postgres
--

ALTER TABLE ONLY payment
    ADD CONSTRAINT fk_payment_user FOREIGN KEY (user_id) REFERENCES "user"(id);

--
-- Name: payment_id_seq; Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON SEQUENCE payment_id_seq TO guest;



COMMIT;
