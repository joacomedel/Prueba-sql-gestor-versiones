CREATE OR REPLACE FUNCTION public.far_abmprecargapedidoparatrazabilidad__()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   	cursorprecarga CURSOR FOR SELECT * FROM tmpprecargarpedido;
	relem RECORD;
	rprecarga RECORD;
--VARIABLES
        elmayorppcp double precision;
        respcomp BOOLEAN;
       /*CREATE TEMP TABLE tmpprecargarpedido ( 
				   idprecargarpedido BIGINT , 
                                   idcentroprecargapedido INTEGER,
				   idusuario integer, 
				   idarticulo bigint, 
				   pcpcantidad integer, 
				   pcppreciocompra double precision, 
				   idpedidoitem bigint, 
				   idcentropedido integer, 
				   idpedido bigint, 
				   pcpfechacargar timestamp without time zone DEFAULT now(), 
				   idcentroarticulo integer DEFAULT centro(), 
				   pcpprecioventasiniva double precision, 
				   pcpprecioventaconiva double precision, 
				   atcodigotrazabilidad character varying,  
				   atcodigobarragtin character varying,  
				   atlote character varying,  
				   atvencimiento date,  
				   numfactura bigint,  
				   idtipocomprobante integer,  
				   fechaemision date,  
				   letra character varying(1),  
				   tipofactura character varying,  
				   numeroregistro bigint,  
				   anio integer,
				   idprestador bigint 
				   idprecargarpedidotraza BIGSERIAL,
				   idcentroprecargarpedidotraza INTEGER DEFAULT centro() 
				   ) WITH OIDS; */

BEGIN
    OPEN cursorprecarga;
    FETCH cursorprecarga into relem;
    WHILE  found LOOP
	RAISE NOTICE 'far_abmprecargapedidoparatrazabilidad__ (%)(%)', relem.accion,relem.numfactura;
	IF (not nullvalue(relem.accion) AND relem.accion = 'guardarCatalogoComprobante' ) THEN 
		SELECT INTO respcomp * FROM  far_abmprecargapedidocatalogocomprobantes();
	ELSE 
	RAISE NOTICE 'far_abmprecargapedidoparatrazabilidad__ (%)(%) 3', relem.accion,relem.numfactura;

		--IF nullvalue(relem.atcodigobarragtin) THEN --MaLaPi 24/05/2017 ahora verifico la accion Se trata de un Articulo
		IF  (not nullvalue(relem.accion) AND relem.accion = 'articulo' ) THEN --Se trata de un Articulo
		     SELECT INTO rprecarga * 
				 FROM far_precargarpedido 
					WHERE idarticulo = relem.idarticulo
					 AND idcentroarticulo = relem.idcentroarticulo
					 AND idusuario = relem.idusuario
					 AND nullvalue(idpedidoitem); 
                     elmayorppcp = (CASE WHEN relem.pcppreciocompra>relem.pcppreciocompracomprobante THEN relem.pcppreciocompra ELSE relem.pcppreciocompracomprobante END);
		     IF NOT FOUND THEN 
			    INSERT INTO far_precargarpedido(idusuario,idarticulo,idcentroarticulo,pcpcantidad,pcppreciocompra,pcpprecioventasiniva,pcpprecioventaconiva)  
				VALUES(relem.idusuario,relem.idarticulo,relem.idcentroarticulo,relem.pcpcantidad,elmayorppcp,relem.pcpprecioventasiniva,relem.pcpprecioventaconiva);
			    relem.idprecargarpedido = currval('far_precargarpedido_idprecargarpedido_seq'::regclass);	
			    relem.idcentroprecargapedido = centro();


			    -- GK 14-09-2022 marco como consumido el articulo del comprobante
			    	UPDATE far_precargapedido_articulo 
					 	SET fechauso=now(),
					 		idprecargarpedido=relem.idprecargarpedido,
					 		idcentroprecargapedido=relem.idcentroprecargapedido
					 	WHERE 
					 		codigobarra = relem.acodigobarra
					 		AND idusuario = relem.idusuario
					 		AND nullvalue(fechauso);
                   --  END IF;

		     ELSE 
				RAISE NOTICE 'far_abmprecargapedidoparatrazabilidad__ (%)(%) 4', relem.accion,relem.numfactura;
				IF(relem.accion = 'comprobante' OR relem.accion = 'trazabilidad' ) THEN 
				      --No te que modificar nada pues viene de las solapas de ABM de Comprobantes y Trazabilidad
				ELSE

				 UPDATE far_precargarpedido SET pcpcantidad = CASE WHEN NOT nullvalue(relem.idprecargarpedido) THEN relem.pcpcantidad ELSE pcpcantidad + relem.pcpcantidad END,
				   pcppreciocompra = elmayorppcp,
				   pcpprecioventasiniva = relem.pcpprecioventasiniva,
				   pcpprecioventaconiva = relem.pcpprecioventaconiva
				  WHERE idarticulo = relem.idarticulo
					 AND idcentroarticulo = relem.idcentroarticulo
					 AND idusuario = relem.idusuario
					 AND nullvalue(idpedidoitem); 
				 relem.idprecargarpedido = rprecarga.idprecargarpedido;	
				 relem.idcentroprecargapedido = rprecarga.idcentroprecargapedido;

                      
			      END IF; --IF(relem.accion = 'comprobante' OR relem.accion = 'trazabilidad' ) THEN 
				
		      	   
		     END IF; --  IF NOT FOUND THEN 
                    --Malapi 24/05/2017 Porque en otros SP se usa la misma tabla temporal y necesito los id de precarga
                      --KR 26-10-17 exista o no la precarga necesito el idprecargarpedido, idcentroprecargapedido
                            UPDATE tmpprecargarpedido SET idprecargarpedido = relem.idprecargarpedido, idcentroprecargapedido = relem.idcentroprecargapedido  
                            WHERE  idarticulo = relem.idarticulo
				AND idcentroarticulo = relem.idcentroarticulo
				AND idusuario = relem.idusuario;	
		END IF; --IF  (not nullvalue(relem.accion) AND relem.accion = 'articulo' ) THEN 
		    RAISE NOTICE 'far_abmprecargapedidoparatrazabilidad__ (%)(%) 2', relem.accion,relem.numfactura;
		    IF not nullvalue(relem.numfactura) THEN
			-- Cargo los datos del comprobante
			--24-02-2017 Malapi Para cargar los comprobantes de venta desde un catalogo. Permite registrar mas de un
			--Precio de compra para un mismo articulo en una precarga.
			SELECT INTO respcomp * FROM far_abmprecargapedidocomprobantesparatrazabilidad();
							
		    END IF;
		--Elimino las pre cargar sin cantidad
		--KR 24-02 pongo la cantidad en 0, al ser sincronizable la tabla no puedo realizar el delete. Se pierde el dato del borrado.
		    UPDATE far_precargarpedido SET pcpcantidad = 0
				WHERE idarticulo = relem.idarticulo
					 AND idcentroarticulo = relem.idcentroarticulo
					 AND idusuario = relem.idusuario
					 AND nullvalue(idpedidoitem)
					 AND (nullvalue(pcpcantidad) OR pcpcantidad <= 0);
	 
		    END IF;
		    IF not nullvalue(relem.atcodigobarragtin) THEN
			-- Cargo los datos de trazabilidad
			SELECT INTO respcomp * FROM far_abmprecargapedidoinformaciontrazabilidad();
			
		    END IF; --IF (not nullvalue(relem.accion) AND relem.accion = 'guardarCatalogoComprobante' ) THEN 
            -- END IF;
             fetch cursorprecarga into relem;
    END LOOP;
    close cursorprecarga;

return 'true';
END;$function$
