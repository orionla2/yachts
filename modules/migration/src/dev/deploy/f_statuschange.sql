-- Deploy f_statuschange
-- requires: users

BEGIN;

--
-- Name: statuschange(integer, integer); Type: FUNCTION; Schema: my_yacht; Owner: postgres
--
SET search_path = my_yacht, pg_catalog;
CREATE OR REPLACE FUNCTION my_yacht.statuschange(bookingid integer, bookingstatus integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare
  ret_id int;
  _usr_id int;
  m_id int;
  msg text;
  _role text;
begin
	IF (SELECT status FROM my_yacht.booking WHERE id = bookingId) <> bookingStatus THEN
		SELECT user INTO _role;
		SELECT user_id FROM my_yacht.booking WHERE id = bookingId INTO _usr_id;
		IF bookingStatus > 5 THEN
			RAISE unique_violation USING MESSAGE = 'wrong status name;';
		END IF;
		IF bookingStatus <> 4 AND _role <> 'manager' THEN
			RAISE unique_violation USING MESSAGE = 'permission denied wrong user role;';
		END IF;
		PERFORM my_yacht.updateBookingStatus(bookingId,bookingStatus);
		-- 1) Active; 2) Pending; 3) Approved; 4) Canceled; 5) Completed;
		--RAISE unique_violation USING MESSAGE = 'bookingId: ' || bookingId || '; bookingStatus: ' || bookingStatus || '; role: ' || _role || ';';
		CASE bookingStatus
			WHEN 3 THEN
				IF _role = 'manager' THEN
					--RAISE unique_violation USING MESSAGE = 'bookingId: ' || bookingId || '; bookingStatus: ' || bookingStatus || '; role: ' || _role || ';';
					msg :=  _usr_id || '.' || _usr_id || '.booking.approvedBooking.email';
					--RAISE unique_violation USING MESSAGE = msg;
					SELECT pg_notify('messanger',msg) into msg;
					msg :=  _usr_id || '.' || _usr_id || '.booking.approvedBooking.push';
					SELECT pg_notify('messanger',msg) into msg;
					msg :=  _usr_id || '.' || _usr_id || '.booking.approvedBooking.sms';
					SELECT pg_notify('messanger',msg) into msg;
				END IF;
			WHEN 4 THEN
				IF _role = 'manager' THEN
					--RAISE unique_violation USING MESSAGE = 'bookingId: ' || bookingId || '; bookingStatus: ' || bookingStatus || '; role: ' || _role || ';';
					msg :=  _usr_id || '.' || _usr_id || '.booking.cancelledBooking.email';
					SELECT pg_notify('messanger',msg) into msg;
					msg :=  _usr_id || '.' || _usr_id || '.booking.cancelledBooking.push';
					SELECT pg_notify('messanger',msg) into msg;
					msg :=  _usr_id || '.' || _usr_id || '.booking.cancelledBooking.sms';
					SELECT pg_notify('messanger',msg) into msg;
				ELSIF _role = 'user_role' THEN
					--RAISE unique_violation USING MESSAGE = 'bookingId: ' || bookingId || '; bookingStatus: ' || bookingStatus || '; role: ' || _role || ';';
					FOR m_id IN SELECT id FROM my_yacht.user WHERE role = 'manager'
					LOOP
						msg :=  _usr_id || '.' || m_id || '.booking.cancelledBooking.email';
						SELECT pg_notify('messanger',msg) into msg;
						msg :=  _usr_id || '.' || m_id || '.booking.cancelledBooking.push';
						SELECT pg_notify('messanger',msg) into msg;
						msg :=  _usr_id || '.' || m_id || '.booking.cancelledBooking.sms';
						SELECT pg_notify('messanger',msg) into msg;
					END LOOP;
				ELSE

				END IF;
			ELSE
		END CASE;
		return true;
	END IF;
	return false;
end
$$;


ALTER FUNCTION my_yacht.statuschange(bookingid integer, bookingstatus integer) OWNER TO postgres;

--
-- Name: statuschange(integer, integer); Type: ACL; Schema: my_yacht; Owner: postgres
--

GRANT ALL ON FUNCTION my_yacht.statuschange(bookingid integer, bookingstatus integer) TO manager;
GRANT ALL ON FUNCTION my_yacht.statuschange(bookingid integer, bookingstatus integer) TO user_role;


COMMIT;
