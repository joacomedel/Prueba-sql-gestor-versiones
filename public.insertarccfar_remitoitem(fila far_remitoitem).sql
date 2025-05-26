CREATE OR REPLACE FUNCTION public.insertarccfar_remitoitem(fila far_remitoitem)
 RETURNS far_remitoitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_remitoitemcc:= current_timestamp;
    UPDATE sincro.far_remitoitem SET centro= fila.centro, far_remitoitemcc= fila.far_remitoitemcc, idarticulo= fila.idarticulo, idcentroremitoitem= fila.idcentroremitoitem, idremito= fila.idremito, idremitoitem= fila.idremitoitem, preciounitario= fila.preciounitario, ricantidad= fila.ricantidad WHERE idcentroremitoitem= fila.idcentroremitoitem AND idremitoitem= fila.idremitoitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_remitoitem(centro, far_remitoitemcc, idarticulo, idcentroremitoitem, idremito, idremitoitem, preciounitario, ricantidad) VALUES (fila.centro, fila.far_remitoitemcc, fila.idarticulo, fila.idcentroremitoitem, fila.idremito, fila.idremitoitem, fila.preciounitario, fila.ricantidad);
    END IF;
    RETURN fila;
    END;
    $function$
