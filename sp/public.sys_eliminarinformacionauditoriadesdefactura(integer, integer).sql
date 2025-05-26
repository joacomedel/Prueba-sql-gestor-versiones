CREATE OR REPLACE FUNCTION public.sys_eliminarinformacionauditoriadesdefactura(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

     pnroregistro alias for $1;
     panio alias for $2;
     cordenesauditadas refcursor;
     unorden record;
     respuesta boolean;

BEGIN
     
     OPEN cordenesauditadas FOR  SELECT * FROM facturaordenesutilizadas 
				WHERE nroregistro = pnroregistro AND anio = panio;
				
     FETCH cordenesauditadas into unorden;
     WHILE FOUND LOOP
	 SELECT INTO respuesta * FROM elimina_preauditoria_odonto(unorden.nroorden::integer, unorden.centro, unorden.tipo::integer);
                
     FETCH cordenesauditadas into unorden;
     END LOOP;
     CLOSE cordenesauditadas;

     SELECT INTO respuesta * FROM far_generapendienteliquidacionauditoria(pnroregistro,panio); 
     
     UPDATE far_ordenventaliquidacionauditada SET ovlaprocesado = false WHERE nroregistro = pnroregistro AND anio = panio;

return respuesta;
END;
$function$
