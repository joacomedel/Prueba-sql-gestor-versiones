CREATE OR REPLACE FUNCTION public.sys_generafiltroconvarchar(paccion character varying, pcampo character varying, pvalores character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare

    respuesta boolean;

BEGIN

respuesta = false;

IF paccion = 'ilike' THEN
	respuesta = pcampo ilike concat('%',pvalores,'%');

END IF;
IF paccion = 'not ilike' THEN
	respuesta = pcampo not ilike concat('%',pvalores,'%');

END IF;
--RAISE NOTICE 'sys_generafiltroconvarchar ---> paccion(%)',paccion;
--RAISE NOTICE 'sys_generafiltroconvarchar ---> pcampo(%)',pcampo;
--RAISE NOTICE 'sys_generafiltroconvarchar ---> pvalores(%)',pvalores;
return respuesta;
END;
$function$
