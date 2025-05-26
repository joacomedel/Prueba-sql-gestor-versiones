CREATE OR REPLACE FUNCTION public.far_abmprecargapedidoparatrazabilidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   	cursorprecarga CURSOR FOR SELECT * FROM tmpprecargarpedido;
	relem RECORD;
	rprecarga RECORD;
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
	IF (not nullvalue(relem.accion) AND relem.accion = 'guardarCatalogoComprobante' ) THEN 
		SELECT INTO respcomp * FROM  far_abmprecargapedidocatalogocomprobantes();
	ELSE 

		IF nullvalue(relem.atcodigobarragtin) THEN --Se trata de un Articulo
		     SELECT INTO rprecarga * 
				 FROM far_precargarpedido 
					WHERE idarticulo = relem.idarticulo
					 AND idcentroarticulo = relem.idcentroarticulo
					 AND idusuario = relem.idusuario
					 AND nullvalue(idpedidoitem); 
		     IF NOT FOUND THEN 
			    INSERT INTO far_precargarpedido(idusuario,idarticulo,idcentroarticulo,pcpcantidad,pcppreciocompra,pcpprecioventasiniva,pcpprecioventaconiva)  
				VALUES(relem.idusuario,relem.idarticulo,relem.idcentroarticulo,relem.pcpcantidad,relem.pcppreciocompra,relem.pcpprecioventasiniva,relem.pcpprecioventaconiva);
			    relem.idprecargarpedido = currval('far_precargarpedido_idprecargarpedido_seq'::regclass);	
			    relem.idcentroprecargapedido = centro();	

		     ELSE 
				IF(relem.accion = 'comprobante' OR relem.accion = 'trazabilidad' ) THEN 
				      --No te que modificar nada pues viene de las solapas de ABM de Comprobantes y Trazabilidad
				ELSE

				 UPDATE far_precargarpedido SET pcpcantidad = pcpcantidad + relem.pcpcantidad,
				   pcppreciocompra = relem.pcppreciocompra,
				   pcpprecioventasiniva = relem.pcpprecioventasiniva,
				   pcpprecioventaconiva = relem.pcpprecioventaconiva
				  WHERE idarticulo = relem.idarticulo
					 AND idcentroarticulo = relem.idcentroarticulo
					 AND idusuario = relem.idusuario
					 AND nullvalue(idpedidoitem); 
				 relem.idprecargarpedido = rprecarga.idprecargarpedido;	
				 relem.idcentroprecargapedido = rprecarga.idcentroprecargapedido;
			      END IF;
				
				   
		     END IF;
	     
		    IF not nullvalue(relem.numfactura) THEN
			-- Cargo los datos del comprobante
			--24-02-2017 Malapi Para cargar los comprobantes de venta desde un catalogo. Permite registrar mas de un
			--Precio de compra para un mismo articulo en una precarga.
			--SELECT INTO respcomp * FROM far_abmprecargapedidocomprobantesparatrazabilidad();
			
			SELECT INTO rprecarga * FROM far_precargarpedidocomprobante 
						WHERE idprecargarpedido = relem.idprecargarpedido
							AND idcentroprecargapedido = relem.idcentroprecargapedido;
			IF FOUND THEN
				UPDATE far_precargarpedidocomprobante SET numfactura = relem.numfactura ,idtipocomprobante= relem.idtipocomprobante,fechaemision= relem.fechaemision,letra= relem.letra,tipofactura= relem.tipofactura,numeroregistro= relem.numeroregistro,anio= relem.anio,idprestador= relem.idprestador
				WHERE idprecargarpedido = relem.idprecargarpedido
				AND idcentroprecargapedido = relem.idcentroprecargapedido; 
			ELSE
				INSERT INTO far_precargarpedidocomprobante (idprecargarpedido,idcentroprecargapedido,numfactura,idtipocomprobante,fechaemision,letra,tipofactura,numeroregistro,anio,idprestador) 
				VALUES (relem.idprecargarpedido,relem.idcentroprecargapedido,relem.numfactura,relem.idtipocomprobante,relem.fechaemision,relem.letra,relem.tipofactura,relem.numeroregistro,relem.anio,relem.idprestador);
			END IF;
							
		    END IF;
		--Elimino las pre cargar sin cantidad
		    /*	DELETE FROM far_precargarpedido 
					WHERE idarticulo = relem.idarticulo
					 AND idcentroarticulo = relem.idcentroarticulo
					 AND idusuario = relem.idusuario
					 AND nullvalue(idpedidoitem)
					 AND (nullvalue(pcpcantidad) OR pcpcantidad <= 0); */
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
			IF nullvalue(relem.idprecargarpedidotraza) THEN
				INSERT INTO far_precargarpedidotraza (idprecargarpedido,idcentroprecargapedido,atcodigotrazabilidad,atcodigobarragtin,atlote,atvencimiento,atserie)
				VALUES (relem.idprecargarpedido,relem.idcentroprecargapedido,relem.atcodigotrazabilidad,relem.atcodigobarragtin,relem.atlote,relem.atvencimiento,relem.atserie);
			ELSE
				
			      IF(relem.accion = 'eliminartraza') THEN 
				  DELETE FROM  far_precargarpedidotraza 
				     WHERE idprecargarpedidotraza = relem.idprecargarpedidotraza
				     AND idcentroprecargarpedidotraza = relem.idcentroprecargarpedidotraza;
			      ELSE
				UPDATE far_precargarpedidotraza SET idprecargarpedidotraza = relem.idprecargarpedidotraza,idcentroprecargarpedidotraza= relem.idcentroprecargarpedidotraza,idprecargarpedido= relem.idprecargarpedido,idcentroprecargapedido= relem.idcentroprecargapedido,atcodigotrazabilidad= relem.atcodigotrazabilidad,atcodigobarragtin= relem.atcodigobarragtin,atlote= relem.atlote,atvencimiento=relem.atvencimiento,atserie = relem.atserie
				WHERE idprecargarpedidotraza = relem.idprecargarpedidotraza AND idcentroprecargarpedidotraza = relem.idcentroprecargarpedidotraza;
			      END IF;
			END IF;
			
		    END IF;
             END IF;
             fetch cursorprecarga into relem;
    END LOOP;
    close cursorprecarga;

return 'true';
END;$function$
