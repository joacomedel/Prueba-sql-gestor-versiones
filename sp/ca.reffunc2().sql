CREATE OR REPLACE FUNCTION ca.reffunc2()
 RETURNS refcursor
 LANGUAGE plpgsql
AS $function$DECLARE
    ref refcursor:='mio';
BEGIN
    OPEN ref FOR SELECT * FROM persona;
    RETURN (ref);
END;
$function$
