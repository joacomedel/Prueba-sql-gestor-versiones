CREATE OR REPLACE FUNCTION public.fix_facturar_colegio_cmgr(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	 resp_control_auditoria BOOLEAN;   
	 reg_oorden  record;
	 cursor_orden refcursor;
	 rfiltros record;
	 rimporteafil record;
	 elcliente  cliente;
	 reg_recibo record;
  	 reg_facturaventa public.facturaventa%rowtype;
	
BEGIN

    /***** 
     El proposito del siguiente script es generar las facturas de ordenes on-line generadas por CMGR que afectaron la 
	 cuenta corriente directamente desde la orden pero no se genero la factura
	 SELECT fix_cuentacoorrientedeuda_remmplazar_orden_x_informe('{nroorden=null}')
    *****/ 
    EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
    IF iftableexists('temp_recibocliente') THEN 
              DROP TABLE temp_recibocliente;
    END IF;
   
    CREATE TEMP TABLE temp_recibocliente (     
					idrecibo bigint,
					centro INTEGER,
			   	        nrodoc VARCHAR,
					idvalorescaja INTEGER  ,
					tipodoc INTEGER,
					nrosucursal INTEGER,
					tipofactura VARCHAR DEFAULT 'FA',
					idformapagotipos INTEGER DEFAULT null,
					fechafactura DATE,
					accion VARCHAR);

    
	
  	OPEN cursor_orden FOR  
	 			SELECT DISTINCT  o.* ,nroregistro,anio, nrodoc,	tipodoc, importe
				FROM orden o
				LEFT JOIN importesorden io USING(nroorden,centro)
				JOIN consumo c  USING(nroorden,centro)
				LEFT JOIN facturaorden USING(nroorden,centro)
				LEFT JOIN cambioestadosorden USING(nroorden,centro)
				LEFT JOIN facturaordenesutilizadas USING(nroorden,centro) 
				WHERE nullvalue(ceofechafin) AND idordenventaestadotipo=1 -- orden emitida
      				   AND idasocconv = 169  --- orden del CMGR
      				   AND o.tipo = 56 --- orden on-line
      				--   AND idformapagotipos = 3 -- para quedarnos con el importe que debe pagar el afiliado 
	  		           AND nullvalue(nrofactura)  -- orden no facturada al afiliado
                                and NOT nullvalue(importe)
			 	--   AND nroorden = rfiltros.nroorden  AND centro = rfiltros.centro ;
				  AND fechaemision>='2025-01-01'	   ; -- sin facturar
--				GROUP BY nroorden,centro;
				 
	        
	FETCH cursor_orden INTO reg_oorden;
	WHILE FOUND LOOP
	
				 RAISE NOTICE '< ORDEN: %-% >' ,  reg_oorden.nroorden , reg_oorden.centro;		
	
				 -- 1 cambio el estado para que quede disponible para facturar desde la caja
				 -- este paso es el que realiza auditoria médica cuando la orden paso el control de facturacion
				
				 SELECT INTO resp_control_auditoria  expendio_cambiarestadoorden (reg_oorden.nroorden , reg_oorden.centro, 9);
				
				
				--- corroboro si hay que facturar al afiliado
				SELECT INTO rimporteafil * 
				FROM importesorden
				WHERE nroorden = reg_oorden.nroorden 
				      AND centro = reg_oorden.centro
					  AND idformapagotipos = 3;
			     IF FOUND  THEN		  
				 	   IF( false and resp_control_auditoria) THEN --- si todo fue correctamenta en control de auditoria 
								-- estamos en condiciones de facturar
								-- 2  Facturo la orden 
								-- a busco el recibo de la orden
								SELECT INTO reg_recibo *
								FROM recibo 
								NATURAL JOIN ordenrecibo 
								WHERE  nroorden = reg_oorden.nroorden 
									   AND  centro = reg_oorden.centro;

								-- b busco los datos del cliente 
								SELECT INTO elcliente * FROM dar_datosclienteos(reg_oorden.nrodoc,reg_oorden.tipodoc::smallint);
								RAISE NOTICE '< CLIENTE > %-% </>' ,  elcliente.nrocliente,elcliente.barra;		
					/********************************************************************************
										OJOOOOOO NO OLVIDAR ENVIAR EL PARAMETRO ,idformapagotipos,idvalorescaja 
								 ********************************************************************************/		
								INSERT INTO temp_recibocliente(idrecibo,centro,nrodoc,tipodoc,accion,fechafactura,nrosucursal,idformapagotipos,idvalorescaja)  
								VALUES(reg_recibo.idrecibo,reg_recibo.centro,elcliente.nrocliente,elcliente.barra,'autogestion', current_date,1002,3,3);

								-- c genero finalmente la factura
							--	SELECT INTO reg_facturaventa * FROM expendio_asentarfacturaventa_global();
								RAISE NOTICE '< Factura > %-% </>' ,  reg_facturaventa.nrofactura,reg_facturaventa.nrosucursal;		

					ELSE 
					      RAISE NOTICE '< ORDEN: %-% > No paso el control de auditoria< /ORDEN >' ,  reg_oorden.nroorden , reg_oorden.centro;		
					END IF;
				ELSE 
					RAISE NOTICE '< ORDEN: %-% > El afiliado no tiene importe a pagar< /ORDEN >' ,  reg_oorden.nroorden , reg_oorden.centro;		
				END IF;
				RAISE NOTICE '</ ORDEN: %-% >' ,  reg_oorden.nroorden , reg_oorden.centro;		
				DELETE FROM temp_recibocliente;
				FETCH cursor_orden INTO reg_oorden;
			 
    END LOOP;
    CLOSE cursor_orden;
    RETURN true;
END;
$function$
