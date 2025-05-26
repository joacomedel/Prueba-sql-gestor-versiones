CREATE OR REPLACE FUNCTION public.reffunc2()
 RETURNS refcursor
 LANGUAGE plpgsql
AS $function$
DECLARE
  ref refcursor;
BEGIN
  OPEN ref FOR SELECT col FROM test;
  RETURN ref;
END;
$function$
