CREATE OR REPLACE FUNCTION ca.probando()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE

 montoform  record;
 sql varchar;
 repuesta record;
BEGIN

SELECT into sql focalculo from ca.formula WHERE idformula=27;

-- EXECUTE 'SELECT focalculo from ca.formula WHERE idformula=34' INTO repuesta  ;
   EXECUTE sql INTO repuesta;
   RAISE NOTICE 'Formula (%) ',repuesta.focalculo;
RETURN true;
END;
$function$
