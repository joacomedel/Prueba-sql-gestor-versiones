CREATE OR REPLACE FUNCTION public.w_emitirfacturasconsumoafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/* SELECT w_emitirfacturasconsumoafiliado('{ "centro": 1, "idrecibo": 794670, "nroorden": 1077115, "ctdescripcion": "Orden online"}');*/
DECLARE
       respuestajson jsonb;
       ivajson jsonb;
       rfacturaventa public.facturaventa%rowtype;
       rrecibo RECORD;
       rdevolver RECORD;
       rcliente RECORD;	
       rverificafactura RECORD;
       rafil RECORD;
	
begin

IF NOT  iftableexists('temp_recibocliente') THEN
	CREATE TEMP TABLE temp_recibocliente (     idrecibo bigint,     centro INTEGER,     nrodoc VARCHAR,     tipodoc INTEGER
	,accion VARCHAR DEFAULT 'autogestion',     idformapagotipos INTEGER,idvalorescaja INTEGER,tipofactura VARCHAR,nrosucursal INTEGER ); 
ELSE 
	DELETE FROM temp_recibocliente;
END IF;


	SELECT INTO rrecibo  idrecibo, centro,consumo.nrodoc,consumo.tipodoc,'autogestion'::varchar as accion,idformapagotipos, CASE WHEN idformapagotipos = 2 THEN 100 ELSE 3 END as idvalorescaja, 1001 as nrosucursal, 'FA'::varchar as tipofactura 
	from orden 
	NATURAL JOIN consumo
	NATURAL JOIN ordenrecibo
        NATURAL JOIN importesrecibo 	
        NATURAL JOIN recibo
	NATURAL JOIN cambioestadosorden
	--LEFT JOIN facturaorden USING(nroorden,centro) --MaLaPi 22-07-2020 Saco estos controles para arreglar un error
      	where tipo = 56 
              --AND nullvalue(nrofactura) 
	      AND nullvalue(ceofechafin)
	      --AND (idordenventaestadotipo = 1) --MaLaPi 22-07-2020 Saco estos controles para arreglar un error
	      AND importerecibo > 0 AND (idformapagotipos = 3 OR idformapagotipos = 2)
	      AND idrecibo = parametro->>'idrecibo' AND centro = parametro->>'centro'; 
	IF FOUND THEN  
	       
                     SELECT INTO rcliente * FROM tesoreria_dardatoscliente(rrecibo.nrodoc) LIMIT 1;
                     IF NOT FOUND THEN
                             RAISE EXCEPTION 'El afiliado no tiene cliente  %',parametro;
                     ELSE
                             -- Verifico que el cliente no sea un afiliado por reciprocidad
                             --RAISE NOTICE 'Datos del cliente % %',rcliente.nrocliente,rcliente.barra ;
                             SELECT INTO rafil * 
                             FROM persona 
                             WHERE nrodoc=rcliente.nrocliente and tipodoc=rcliente.barra
                                    and persona.barra>=100 AND ( persona.barra<>149 AND persona.barra<>131 );
                             IF  FOUND THEN
                                    INSERT INTO  recibo_wsafip_error (idrecibo,centro,raemensaje)VALUES(rrecibo.idrecibo,rrecibo.centro,'El titular es de RECI');                         
                             ELSE  
		                    INSERT INTO temp_recibocliente (idrecibo,centro,nrodoc,tipodoc,accion,idformapagotipos,idvalorescaja,nrosucursal,tipofactura)
		VALUES(rrecibo.idrecibo,rrecibo.centro,rcliente.nrocliente,rcliente.barra,rrecibo.accion,rrecibo.idformapagotipos,rrecibo.idvalorescaja,rrecibo.nrosucursal,rrecibo.tipofactura);

	                            SELECT INTO rfacturaventa * FROM expendio_asentarfacturaventa_global();
                                  

                                   --MaLaPi 28-08-2019 Cambio la fecha del comprobante para que refleje que se emitio hoy
                                   UPDATE facturaventa SET fechaemision = CURRENT_DATE
                                   WHERE nrofactura =rfacturaventa.nrofactura and nrosucursal= rfacturaventa.nrosucursal 
                                         and tipofactura =rfacturaventa.tipofactura
			                 and tipocomprobante = rfacturaventa.tipocomprobante; 
               
               
	                           --Verifico que el convenio sea valido o este vigente.
		                   INSERT INTO facturaventa_wsafip(tipocomprobante,nrosucursal,nrofactura,tipofactura,idrecibo,centro) VALUES(rfacturaventa.tipocomprobante,rfacturaventa.nrosucursal,rfacturaventa.nrofactura,rfacturaventa.tipofactura,rrecibo.idrecibo,rrecibo.centro);
		                  

 SELECT  INTO rdevolver *
	from facturaventa
	WHERE nrofactura =  rfacturaventa.nrofactura AND nrosucursal =  rfacturaventa.nrosucursal
		                         AND tipofactura =  rfacturaventa.tipofactura AND tipocomprobante =  rfacturaventa.tipocomprobante; 



                                   --Malapi 02-08-2019 Si la factura tiene importe 0, no debe ser generada, largo un error. 
                                   IF (rdevolver.importeefectivo + rdevolver.importectacte) = 0 THEN 
                                           RAISE EXCEPTION 'La factura tiene importe cero  %',rdevolver;
                               
                                   END IF;
               	
		                   respuestajson = row_to_json(rdevolver);

                                END IF;
                             
	           END IF;
       END IF;

      return respuestajson;

end;$function$
