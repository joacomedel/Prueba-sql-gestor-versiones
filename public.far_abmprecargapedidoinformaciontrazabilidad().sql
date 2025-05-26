CREATE OR REPLACE FUNCTION public.far_abmprecargapedidoinformaciontrazabilidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   	cursorprecargatrazabilidad CURSOR FOR SELECT * FROM tmpprecargarpedido;
	relem RECORD;
	rprecarga RECORD;
	rverifica RECORD;
        respcomp BOOLEAN;
BEGIN
    OPEN cursorprecargatrazabilidad;
    FETCH cursorprecargatrazabilidad into relem;
    WHILE  found LOOP
	    IF not nullvalue(relem.atcodigobarragtin) THEN
			-- Cargo los datos de trazabilidad
			IF not nullvalue(relem.accion) 
				AND relem.accion = 'trazabilidad'  THEN
								
				SELECT INTO rverifica * FROM far_precargarpedidotraza 
				WHERE  idprecargarpedido= relem.idprecargarpedido 
					AND idcentroprecargapedido= relem.idcentroprecargapedido
					AND pptborrado = FALSE
					AND atcodigobarragtin = relem.atcodigobarragtin
					AND atlote = relem.atlote
					AND atvencimiento = relem.atvencimiento
					AND atserie = relem.atserie;
				IF NOT FOUND THEN 
					INSERT INTO far_precargarpedidotraza(idprecargarpedido,idcentroprecargapedido,atcodigotrazabilidad,atcodigobarragtin,atlote,atvencimiento,atserie)
					VALUES (relem.idprecargarpedido,relem.idcentroprecargapedido,relem.atcodigotrazabilidad,relem.atcodigobarragtin,relem.atlote,relem.atvencimiento,relem.atserie);
				ELSE
					-- No se puede modificar, directamente hay que eliminarlo

				END IF;
				
				ELSE
			      IF(relem.accion = 'eliminartraza') THEN 
				  UPDATE far_precargarpedidotraza SET pptborrado = TRUE
				  WHERE idprecargarpedidotraza = relem.idprecargarpedidotraza AND idcentroprecargarpedidotraza = relem.idcentroprecargarpedidotraza;
			      ELSE
				 UPDATE far_precargarpedidotraza SET idprecargarpedidotraza = relem.idprecargarpedidotraza
				 ,idcentroprecargarpedidotraza= relem.idcentroprecargarpedidotraza
				,idprecargarpedido= relem.idprecargarpedido,idcentroprecargapedido= relem.idcentroprecargapedido
				,atcodigotrazabilidad= relem.atcodigotrazabilidad
				,atcodigobarragtin= relem.atcodigobarragtin,atlote= relem.atlote
				,atvencimiento=relem.atvencimiento,atserie = relem.atserie
				 WHERE idprecargarpedidotraza = relem.idprecargarpedidotraza AND idcentroprecargarpedidotraza = relem.idcentroprecargarpedidotraza;
			      END IF;
			END IF;

			 IF not nullvalue(relem.idarticulotraza) THEN --Se esta usando la interfaz de trazabilidad de verifarma
				  SELECT INTO rprecarga * 
						FROM far_precargarpedidocomprobantearticulo 
						WHERE idprecargarpedido = relem.idprecargarpedido
						AND idcentroprecargapedido = relem.idprecargarpedidocompcatalogo
						AND idprecargarpedidocompcatalogo = relem.idprecargarpedido
						AND idcentroprecargarpedidocompcatalogo = relem.idcentroprecargarpedidocompcatalogo;

				UPDATE far_articulotrazabilidad SET 
				--idarticulocomprobantecompra = rprecarga.idarticulocomprobantecompra
				--,idcentroarticulocomprobantecompra = rprecarga.idcentroarticulocomprobantecompra
				idprecargarpedido = relem.idprecargarpedido
				,idcentroprecargapedido = relem.idcentroprecargapedido
				WHERE idarticulotraza=relem.idarticulotraza AND idcentroarticulotraza = relem.idcentroarticulotraza;

				UPDATE far_articulotrazabilidadestado SET atefechafin = NOW()
				WHERE nullvalue(atefechafin) AND idarticulotraza=relem.idarticulotraza AND idcentroarticulotraza = relem.idcentroarticulotraza;
				INSERT INTO far_articulotrazabilidadestado( idarticulotrazabilidadestadotipos, idarticulotraza, idcentroarticulotraza, atedescripcion)
				VALUES (2, relem.idarticulotraza, relem.idcentroarticulotraza, concat('Producto seleccionado para ser recibido en precargar',relem.idprecargarpedido,'-',relem.idcentroprecargapedido));

			 END IF;

			
		    END IF;


             fetch cursorprecargatrazabilidad into relem;
    END LOOP;
    close cursorprecargatrazabilidad;

return 'true';
END;$function$
