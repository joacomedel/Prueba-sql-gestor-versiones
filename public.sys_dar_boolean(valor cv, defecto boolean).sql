CREATE OR REPLACE FUNCTION public.sys_dar_boolean(valor character varying, defecto boolean)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	vvalor boolean;
BEGIN 
 

     vvalor =  CASE WHEN (trim(valor) = 'SI' OR  trim(valor) = 'si' OR  trim(valor) = 'TRUE' OR  trim(valor) = 'true' ) THEN true
                  WHEN (trim(valor) = 'NO' OR  trim(valor) = 'no' OR  trim(valor) = 'FALSE' OR  trim(valor) = 'false' ) THEN false
               ELSE defecto
              :: boolean END;    

    
     return vvalor;
END;
$function$
