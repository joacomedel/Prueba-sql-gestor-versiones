CREATE OR REPLACE FUNCTION public.sys_dar_valorsinull(valor character varying, defecto character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
	vvalor character varying;
BEGIN 
   --valor = replace(valor,'%','');
   vvalor =  CASE when (trim(valor) = '' OR nullvalue(valor) ) then defecto else valor  END;
     return vvalor;
END;
$function$
