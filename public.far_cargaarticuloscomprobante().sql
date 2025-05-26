CREATE OR REPLACE FUNCTION public.far_cargaarticuloscomprobante()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD
        rarticuloscomprobante record;
 
        

--CURSOR
        carticuloscomprobante  refcursor;

respuesta character varying;


        

BEGIN

    OPEN carticuloscomprobante FOR SELECT * 
                                   FROM   far_temparticulocomprobante as t
                                   LEFT JOIN far_precargapedido_articulo AS fpa ON  (t.codigobarra=fpa.codigobarra AND t.preciocomprobante=fpa.preciocomprobante AND fpa.cantidad=t.cantidad AND nullvalue(fechauso))
                                   WHERE nullvalue(idprecargacomprobante); --(CASE WHEN nullvalue(idprecargacomprobante) THEN true ELSE NOT nullvalue(fpa.fechauso) END);
    FETCH carticuloscomprobante into rarticuloscomprobante;

    WHILE  found LOOP
            INSERT INTO far_precargapedido_articulo (fila,codigobarra,preciocomprobante,cantidad,fechacarga,archivonombre,idusuario,fechauso,transaccion)
            VALUES (
                    rarticuloscomprobante.fila,
                    rarticuloscomprobante.codigobarra,
                    rarticuloscomprobante.preciocomprobante,
                    rarticuloscomprobante.cantidad,
                    now(),
                    rarticuloscomprobante.archivonombre,
                    rarticuloscomprobante.idusuario,
                    null,
                    rarticuloscomprobante.transaccion
                );
        FETCH carticuloscomprobante into rarticuloscomprobante;
    END LOOP;
    respuesta='TODO OK';
    RETURN respuesta;

END;$function$
