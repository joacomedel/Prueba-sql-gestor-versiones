CREATE OR REPLACE FUNCTION public.sys_eliminanotificacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
  DECLARE
  BEGIN

   IF not nullvalue(NEW.adfechaproceso) OR not nullvalue(NEW.adfechacargar) THEN
        UPDATE infoafiliado SET iafechafin = now() WHERE (idinfoafiliado,idcentroinfoafiliado) IN (
		SELECT idinfoafiliado,idcentroinfoafiliado 
			FROM w_afiliados_notificados 
			WHERE nrodoc = NEW.nrodoc AND idtiposdoc = NEW.idtiposdoc
	);
   END IF;
   
   RETURN NEW;
  END;
$function$
