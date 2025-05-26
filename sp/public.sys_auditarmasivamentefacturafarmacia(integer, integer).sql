CREATE OR REPLACE FUNCTION public.sys_auditarmasivamentefacturafarmacia(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE

     pnroregistro alias for $1;
     panio alias for $2;
     cordenesauditadas refcursor;
     unorden record;
     respuesta boolean;

BEGIN
     
     SELECT INTO respuesta * FROM far_generapendienteliquidacionauditoria(pnroregistro,panio);

     IF FOUND THEN 
	     OPEN cordenesauditadas FOR  SELECT * FROM far_ordenventaliquidacionauditada 
					WHERE nroregistro = pnroregistro AND anio = panio AND not ovlaprocesado
					ORDER BY idordenventaliquidacionauditada;
					
					
	     FETCH cordenesauditadas into unorden;
	     WHILE FOUND LOOP
		   SELECT INTO respuesta * FROM far_procesar_pendienteliquidacionauditoria(unorden.idordenventaliquidacionauditada);      
	     FETCH cordenesauditadas into unorden;
	     END LOOP;
	     CLOSE cordenesauditadas;

	     IF respuesta THEN 
		SELECT INTO respuesta * FROM far_procesaliquidacionordenreci(pnroregistro,panio);
	     END IF;
 END IF;
return true;
END;
$function$
