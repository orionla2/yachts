-- Deploy f_updatebookingstatus
-- requires: schema_pure

BEGIN;

--
-- Name: updatebookingstatus(integer, integer); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--

CREATE OR REPLACE FUNCTION my_yacht.updatebookingstatus(bookingid integer, bookingstatus integer) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
UPDATE my_yacht.booking SET status = bookingStatus WHERE id = bookingId;
end
$$;


ALTER FUNCTION my_yacht.updatebookingstatus(bookingid integer, bookingstatus integer) OWNER TO postgres;


COMMIT;
