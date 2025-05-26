CREATE OR REPLACE FUNCTION public.w_registrarfacturaconsumoafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*

Este proceso se llama desde el WS, para regitrar la informacion del CAE de la factura
*{"centro": 1, "idrecibo": 785695, "nroorden": 1014722, "ctdescripcion": "Orden online", "CAE" : "1313232313", "CAEFchVto":"2019-07-17"
,"nrofacturaafip":12331 , "CbteTipo":6 }"

*/
DECLARE
       respuestajson jsonb;
       rfacturaventa RECORD;
       rrecibo RECORD;
       rreciboerror RECORD;
       rdevolver RECORD;
       elmayor BIGINT;
       vcentro INTEGER;
       vtipocomprobante  VARCHAR;
       vidrecibo BIGINT;
	
begin

/*IF NOT  iftableexists('temp_recibocliente') THEN
	CREATE TEMP TABLE temp_recibocliente (     idrecibo bigint,     centro INTEGER,     nrodoc VARCHAR,     tipodoc INTEGER
	,accion VARCHAR DEFAULT 'autogestion',     idformapagotipos INTEGER,idvalorescaja INTEGER,tipofactura VARCHAR,nrosucursal INTEGER ); 
ELSE 
	DELETE FROM temp_recibocliente;
END IF;
*/	

	SELECT INTO rfacturaventa *,parametro->>'respuesta' as respuesta,parametro->>'mensaje' as mensaje FROM facturaventa_wsafip 
				    WHERE 
					--concat(idrecibo,'-',centro) = parametro->>'Recibo'
					nrofactura = parametro->>'CbteDesde'  AND nrosucursal = parametro->>'PtoVta' 
				    AND tipofactura = CASE WHEN parametro->>'CbteTipo' = 6 OR parametro->>'CbteTipo' = 1 THEN 'FA' ELSE 'NC' END
                                    AND tipocomprobante = CASE WHEN parametro->>'CbteTipo' = 6 OR parametro->>'CbteTipo' = 8 THEN 1 ELSE 2 END
                                    AND nullvalue(nrofacturafiscal); 
	IF FOUND THEN  
	

       --MaLapi 24-07-2019 Hay que verificar si el WS dio un error o no.

         IF parametro->>'respuesta' = 'false'  THEN  --Hay un error
            -- PERFORM far_eliminarcomprobantenoemitido_arregla_talonario(rfacturaventa.nrofactura,rfacturaventa.nrosucursal,rfacturaventa.tipocomprobante,rfacturaventa.tipofactura);
             --DELETE FROM facturaventa_wsafip WHERE nrofactura = rfacturaventa.nrofactura AND nrosucursal = rfacturaventa.nrosucursal AND  tipocomprobante = rfacturaventa.tipocomprobante AND tipofactura = rfacturaventa.tipofactura;

             vcentro = CASE WHEN nullvalue(rfacturaventa.idrecibo) THEN rfacturaventa.idcentroregionaluso ELSE rfacturaventa.centro END;
             vtipocomprobante = CASE WHEN nullvalue(rfacturaventa.idrecibo) THEN 'aportes' ELSE 'ordenes' END;
             vidrecibo = CASE WHEN nullvalue(rfacturaventa.idrecibo) THEN rfacturaventa.idaporte ELSE rfacturaventa.idrecibo END;

             UPDATE recibo_wsafip_error SET raefechacreacion = now(), raemensaje = concat(raemensaje,'|',parametro->>'mensaje'),raefechacorrerws = now()
             WHERE idrecibo = vidrecibo  AND centro = vcentro AND  tipofactura = rfacturaventa.tipofactura;
             IF NOT FOUND THEN 
                 INSERT INTO  recibo_wsafip_error (tipomovimiento,idrecibo,centro, tipofactura,raemensaje) VALUES (vtipocomprobante,vidrecibo,vcentro,rfacturaventa.tipofactura,parametro->>'mensaje');
             END IF;

         ELSE 



		UPDATE facturaventa_wsafip SET fvafechacorrerws=now(),nrofacturafiscal = trim(parametro->>'nrofacturaafip')::bigint,fvcae = parametro->>'CAE',fvcaefchvto = trim(parametro->>'CAEFchVto')::date
		WHERE tipocomprobante = rfacturaventa.tipocomprobante AND nrosucursal = rfacturaventa.nrosucursal 
		AND nrofactura = rfacturaventa.nrofactura AND tipofactura = rfacturaventa.tipofactura; 


                SELECT INTO rfacturaventa *,parametro->>'respuesta' as respuesta,parametro->>'mensaje' as mensaje 
                                    FROM facturaventa_wsafip 
                                    JOIN facturaventa USING(nrofactura,nrosucursal,tipofactura,tipocomprobante) 
				    WHERE ( concat(idrecibo,'-',facturaventa_wsafip.centro) = parametro->>'Recibo'  
                                                                                            OR concat(idaporte,'-','1')  = parametro->>'Recibo' )
                                    AND fvafechacreacion = rfacturaventa.fvafechacreacion
				    AND tipofactura = CASE WHEN parametro->>'CbteTipo' = 6 THEN 'FA' ELSE 'NC' END
                                    ; 


		IF(rfacturaventa.nrofacturafiscal <> rfacturaventa.nrofactura) THEN 
			--Hay que renumerar.
		 INSERT INTO configuraadminprocesosejecucion(idconfiguraadminprocesos,capedescripcion)
		 VALUES(99,concat('VAS 03012020: Voy a cambiar el nro del comprobante ',rfacturaventa.tipofactura,' ',rfacturaventa.nrofactura,'-',rfacturaventa.nrosucursal,'/',rfacturaventa.tipocomprobante,' por el nro ',rfacturaventa.nrofacturafiscal));
		
		/* UPDATE facturaventa SET nrofactura = rfacturaventa.nrofacturafiscal
			WHERE nrofactura =rfacturaventa.nrofactura and nrosucursal= rfacturaventa.nrosucursal and tipofactura =rfacturaventa.tipofactura
			and tipocomprobante = rfacturaventa.tipocomprobante;

		 -- Arreglo el talonario
		     SELECT INTO elmayor max(nrofactura)
		     FROM facturaventa
			WHERE nrosucursal= rfacturaventa.nrosucursal and tipofactura =rfacturaventa.tipofactura
			and tipocomprobante = rfacturaventa.tipocomprobante;

		      UPDATE talonario SET sgtenumero = elmayor + 1
		      WHERE nrosucursal= rfacturaventa.nrosucursal and tipofactura =rfacturaventa.tipofactura
			and tipocomprobante = rfacturaventa.tipocomprobante;
               */

		END IF;
              END IF;
		
		respuestajson = row_to_json(rfacturaventa);

		--RAISE EXCEPTION 'respuestajson  %',respuestajson;
	END IF;
      return respuestajson;

end;$function$
