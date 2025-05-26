CREATE OR REPLACE FUNCTION public.far_abmprecargapedidocatalogocomprobantes()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

   	cursorprecargacatalogo CURSOR FOR SELECT * FROM tmpprecargarpedido;
	relem RECORD;
	rprecargacomp RECORD;
BEGIN
    OPEN cursorprecargacatalogo;
    FETCH cursorprecargacatalogo into relem;
    WHILE  found LOOP
           IF (relem.accion = 'guardarCatalogoComprobante') THEN
		SELECT INTO rprecargacomp * FROM far_precargarpedidocompcatalogo 
					    WHERE  idprecargarpedidocompcatalogo = relem.idprecargarpedidocompcatalogo
						AND idcentroprecargarpedidocompcatalogo = relem.idcentroprecargarpedidocompcatalogo;
		IF FOUND THEN
			UPDATE far_precargarpedidocompcatalogo SET numfactura = relem.numfactura ,idtipocomprobante= relem.idtipocomprobante,fechaemision= relem.fechaemision,letra= relem.letra
								,tipofactura= relem.tipofactura
								,numeroregistro= relem.numeroregistro,anio= relem.anio
								,idprestador= relem.idprestador
								,idusuario = relem.idusuario
								,pcpccactivo = relem.pcpccactivo
			WHERE idprecargarpedidocompcatalogo = relem.idprecargarpedidocompcatalogo
						AND idcentroprecargarpedidocompcatalogo = relem.idcentroprecargarpedidocompcatalogo;
                        -- MaLaPi 25-07-2018 modifico la informacion de las pre cargas que apuntan a ese comprobante
                        UPDATE far_precargarpedidocomprobante SET numfactura = relem.numfactura ,idtipocomprobante= relem.idtipocomprobante,fechaemision= relem.fechaemision,letra= relem.letra,tipofactura= relem.tipofactura,numeroregistro= relem.numeroregistro,anio= relem.anio,idprestador= relem.idprestador
				WHERE  idprecargarpedidocompcatalogo= relem.idprecargarpedidocompcatalogo
                                AND idcentroprecargarpedidocompcatalogo = relem.idcentroprecargarpedidocompcatalogo ; 

		ELSE 
			INSERT INTO far_precargarpedidocompcatalogo(numfactura,idtipocomprobante,fechaemision,letra,tipofactura,numeroregistro,anio,idprestador,idusuario) 
			VALUES (relem.numfactura,relem.idtipocomprobante,relem.fechaemision,relem.letra,relem.tipofactura,relem.numeroregistro,relem.anio,relem.idprestador,relem.idusuario);
		END IF;
           END IF;
            
        fetch cursorprecargacatalogo into relem;
    END LOOP;
    close cursorprecargacatalogo;

return 'true';
END;$function$
