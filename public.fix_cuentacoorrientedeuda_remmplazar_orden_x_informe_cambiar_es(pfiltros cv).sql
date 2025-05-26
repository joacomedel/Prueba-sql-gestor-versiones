CREATE OR REPLACE FUNCTION public.fix_cuentacoorrientedeuda_remmplazar_orden_x_informe_cambiar_es(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
    arr varchar[];
    array_len integer;
    rfiltros record;
    vquery varchar;
	  idinformefacturacion INTEGER;
	elconcepto varchar;  
	velcomprobantetipo INTEGER;
	reg_oorden  record;
	cursor_orden refcursor;
    reg_facturaventa  record; 
    reg_informefacturacion  record;
	  rmvtoctacte RECORD;
	 rorigenctacte RECORD;
	  vcrearinforme BOOLEAN;
	  elcentroinforme INTEGER;
	  eltipoinforme  INTEGER;
BEGIN

    /***** 
     El proposito del siguiente script es generar las facturas de ordenes on-line generadas por CMGR que afectaron la 
	 cuenta corriente directamente desde la orden pero no se genero la factura
	 SELECT fix_cuentacoorrientedeuda_remmplazar_orden_x_informe('{nroorden=null}')
    *****/ 
    EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
  	 OPEN cursor_orden FOR  
	 			SELECT ----facturaorden.* ,
cambioestadosorden.*
----    DISTINCT o.* , io.importe as imp_afil_importe,nrodoc,tipodoc,iddeuda,idcentrodeuda
			FROM orden o
			JOIN importesorden io USING(nroorden,centro)
			JOIN facturaorden USING(nroorden,centro)
			LEFT JOIN cambioestadosorden USING(nroorden,centro) 		
			WHERE   nullvalue(ceofechafin)
        			AND idasocconv = 169
      				AND tipo = 56 
      				AND idformapagotipos = 3 -- para quedarnos con el importe que debe pagar el afiliado 
				AND idordenventaestadotipo=1 			    ----    AND NOT nullvalue(nrodoc) ---OJO HAY QUE VER ESTA ORDEN
			ORDER BY o.nroorden
				;
	 
	        
	FETCH cursor_orden INTO reg_oorden;
	WHILE FOUND LOOP
            -- 1 Actualizo la fecha fin del estado actual de la orden
			UPDATE cambioestadosorden SET ceofechafin = now()
			WHERE nullvalue(ceofechafin) 
			       AND nroorden = reg_oorden.nroorden
				   AND centro = reg_oorden.centro;
			-- 2 Inserto el nuevo estado
			  RAISE NOTICE '<Se modifico el estado actual : %/%>' ,  reg_oorden.nroorden , reg_oorden.centro;							   
      		 /*hay que cambiar de estado a la orden y pponerla como facturada */
			  RAISE NOTICE '/***********************************************************************************************/' ;
			  INSERT INTO cambioestadosorden (	nroorden,centro, idordenventaestadotipo	)VALUES(reg_oorden.nroorden,reg_oorden.centro,3);
			  RAISE NOTICE '<Se inserto el estado actual : %/%>' ,  reg_oorden.nroorden , reg_oorden.centro;							   
              FETCH cursor_orden INTO reg_oorden;
			 
    END LOOP;
    CLOSE cursor_orden;
    RETURN true;
END;
$function$
