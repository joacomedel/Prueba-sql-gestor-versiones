CREATE OR REPLACE FUNCTION public.reffunc(refcursor)
 RETURNS refcursor
 LANGUAGE plpgsql
AS $function$
BEGIN
  OPEN $1 FOR SELECT col FROM test;
  RETURN $1;
END;
$function$
