CREATE OR REPLACE FUNCTION ca.reffunc(refcursor)
 RETURNS refcursor
 LANGUAGE plpgsql
AS $function$
BEGIN
    OPEN $1 FOR SELECT * FROM persona;
    RETURN $1;
END;
$function$
