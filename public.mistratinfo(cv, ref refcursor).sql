CREATE OR REPLACE FUNCTION public.mistratinfo(character varying, ref refcursor)
 RETURNS refcursor
 LANGUAGE plpgsql
AS $function$
    DECLARE
      --ref refcursor;                                                     -- Declare a cursor variable
    BEGIN
      OPEN ref FOR SELECT * FROM persona WHERE nrodoc = $1;   -- Open a cursor
      RETURN ref;                                                       -- Return the cursor to the caller
    END;
    $function$
