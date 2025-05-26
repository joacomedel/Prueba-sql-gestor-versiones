CREATE OR REPLACE FUNCTION public.ejecutar(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

BEGIN

	EXECUTE $1;

    return true;
END;
$function$
