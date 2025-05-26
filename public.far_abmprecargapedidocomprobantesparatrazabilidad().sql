CREATE OR REPLACE FUNCTION public.far_abmprecargapedidocomprobantesparatrazabilidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   	cursorprecargacomprobante CURSOR FOR SELECT * FROM tmpprecargarpedido;
	relem RECORD;
	rprecarga RECORD;
        rprecargacomp RECORD;
BEGIN
    OPEN cursorprecargacomprobante;
    FETCH cursorprecargacomprobante into relem;
    WHILE  found LOOP
	    RAISE NOTICE 'far_abmprecargapedidocomprobantesparatrazabilidad (%)(%)', relem.idprecargarpedidocompcatalogo,relem.numfactura;
	    IF nullvalue(relem.idprecargarpedidocompcatalogo) 
		AND not nullvalue(relem.numfactura) THEN -- Se usa la ventana para carga de comprobantes

		 SELECT INTO rprecarga * FROM far_precargarpedidocomprobante 
						WHERE idprecargarpedido = relem.idprecargarpedido
						AND idcentroprecargapedido = relem.idcentroprecargapedido;
			IF FOUND THEN
				UPDATE far_precargarpedidocomprobante SET numfactura = relem.numfactura ,idtipocomprobante= relem.idtipocomprobante,fechaemision= relem.fechaemision,letra= relem.letra,tipofactura= relem.tipofactura,numeroregistro= relem.numeroregistro,anio= relem.anio,idprestador= relem.idprestador
				WHERE idprecargarpedido = relem.idprecargarpedido
				AND idcentroprecargapedido = relem.idcentroprecargapedido; 
			ELSE
				INSERT INTO far_precargarpedidocomprobante(idprecargarpedido,idcentroprecargapedido,numfactura,idtipocomprobante,fechaemision,letra,tipofactura,numeroregistro,anio,idprestador) 
				VALUES (relem.idprecargarpedido,relem.idcentroprecargapedido,relem.numfactura,relem.idtipocomprobante,relem.fechaemision,relem.letra,relem.tipofactura,relem.numeroregistro,relem.anio,relem.idprestador);
			END IF;


            END IF ;
            IF not nullvalue(relem.idprecargarpedidocompcatalogo) THEN

                       SELECT INTO rprecarga * FROM far_precargarpedidocomprobante 
						WHERE idprecargarpedido = relem.idprecargarpedido
						AND idcentroprecargapedido = relem.idcentroprecargapedido
                                                AND idprecargarpedidocompcatalogo= relem.idprecargarpedidocompcatalogo
                                                AND idcentroprecargarpedidocompcatalogo = relem.idcentroprecargarpedidocompcatalogo;
--Malapi 07-11-2017 Comento la busqueda por nrofactura pues ahora siempre se usa el catalogo y el idprecargarpedidocompcatalogo debe determinar siempre el numfactura
                                               --AND numfactura =  relem.numfactura;
			IF FOUND THEN
				UPDATE far_precargarpedidocomprobante SET numfactura = relem.numfactura ,idtipocomprobante= relem.idtipocomprobante,fechaemision= relem.fechaemision,letra= relem.letra,tipofactura= relem.tipofactura,numeroregistro= relem.numeroregistro,anio= relem.anio,idprestador= relem.idprestador
				WHERE idprecargarpedido = relem.idprecargarpedido
				AND idcentroprecargapedido = relem.idcentroprecargapedido
                                AND idprecargarpedidocompcatalogo= relem.idprecargarpedidocompcatalogo
                                AND idcentroprecargarpedidocompcatalogo = relem.idcentroprecargarpedidocompcatalogo ; 
			ELSE
				INSERT INTO far_precargarpedidocomprobante (idprecargarpedido,idcentroprecargapedido,numfactura,idtipocomprobante,fechaemision,letra,tipofactura,numeroregistro,anio,idprestador,idprecargarpedidocompcatalogo,idcentroprecargarpedidocompcatalogo) 
				VALUES (relem.idprecargarpedido,relem.idcentroprecargapedido,relem.numfactura,relem.idtipocomprobante,relem.fechaemision,relem.letra,relem.tipofactura,relem.numeroregistro,relem.anio,relem.idprestador,relem.idprecargarpedidocompcatalogo,relem.idcentroprecargarpedidocompcatalogo );
			END IF;


		SELECT INTO rprecargacomp * FROM far_precargarpedidocomprobantearticulo 
					    WHERE idprecargarpedidocompcatalogo = relem.idprecargarpedidocompcatalogo
					    AND idcentroprecargarpedidocompcatalogo = relem.idcentroprecargarpedidocompcatalogo
					    AND idprecargarpedido = relem.idprecargarpedido
					    AND idcentroprecargapedido = relem.idcentroprecargapedido;
		IF FOUND THEN
			UPDATE far_precargarpedidocomprobantearticulo SET pcpcacantidad = CASE WHEN nullvalue(relem.pcpcacantidad) THEN pcpcacantidad ELSE relem.pcpcacantidad END 
,pcpcapreciocompra = CASE WHEN nullvalue(relem.pcppreciocompracomprobante) THEN relem.pcppreciocompra ELSE relem.pcppreciocompracomprobante END 
			WHERE idprecargarpedidocompcatalogo = relem.idprecargarpedidocompcatalogo
					    AND idcentroprecargarpedidocompcatalogo = relem.idcentroprecargarpedidocompcatalogo
					    AND idprecargarpedido = relem.idprecargarpedido
					    AND idcentroprecargapedido = relem.idcentroprecargapedido;
                ELSE
			INSERT INTO far_precargarpedidocomprobantearticulo(idprecargarpedido,idcentroprecargapedido,pcpcacantidad,pcpcapreciocompra,idprecargarpedidocompcatalogo,idcentroprecargarpedidocompcatalogo) 
			VALUES (relem.idprecargarpedido,relem.idcentroprecargapedido,CASE WHEN nullvalue(relem.pcpcacantidad) THEN rprecargacomp.pcpcacantidad ELSE relem.pcpcacantidad END, CASE WHEN nullvalue(relem.pcppreciocompracomprobante) THEN relem.pcppreciocompra ELSE relem.pcppreciocompracomprobante END,relem.idprecargarpedidocompcatalogo,relem.idcentroprecargarpedidocompcatalogo);
                END IF;
						
            END IF;
            
        fetch cursorprecargacomprobante into relem;
    END LOOP;
    close cursorprecargacomprobante;

return 'true';
END;$function$
