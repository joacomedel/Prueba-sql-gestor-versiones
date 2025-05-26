CREATE OR REPLACE FUNCTION public.insertarccfar_pedidoreclibrofact(fila far_pedidoreclibrofact)
 RETURNS far_pedidoreclibrofact
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_pedidoreclibrofactcc:= current_timestamp;
    UPDATE sincro.far_pedidoreclibrofact SET anio= fila.anio, far_pedidoreclibrofactcc= fila.far_pedidoreclibrofactcc, idcentropedido= fila.idcentropedido, idpedido= fila.idpedido, numeroregistro= fila.numeroregistro, prcomentario= fila.prcomentario, prffecha= fila.prffecha WHERE anio= fila.anio AND idcentropedido= fila.idcentropedido AND idpedido= fila.idpedido AND numeroregistro= fila.numeroregistro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_pedidoreclibrofact(anio, far_pedidoreclibrofactcc, idcentropedido, idpedido, numeroregistro, prcomentario, prffecha) VALUES (fila.anio, fila.far_pedidoreclibrofactcc, fila.idcentropedido, fila.idpedido, fila.numeroregistro, fila.prcomentario, fila.prffecha);
    END IF;
    RETURN fila;
    END;
    $function$
