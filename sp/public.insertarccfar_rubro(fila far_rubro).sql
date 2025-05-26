CREATE OR REPLACE FUNCTION public.insertarccfar_rubro(fila far_rubro)
 RETURNS far_rubro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_rubrocc:= current_timestamp;
    UPDATE sincro.far_rubro SET far_rubrocc= fila.far_rubrocc, idrubro= fila.idrubro, idtipopedido= fila.idtipopedido, rdescripcion= fila.rdescripcion, rporcentajeganacia= fila.rporcentajeganacia WHERE idrubro= fila.idrubro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_rubro(far_rubrocc, idrubro, idtipopedido, rdescripcion, rporcentajeganacia) VALUES (fila.far_rubrocc, fila.idrubro, fila.idtipopedido, fila.rdescripcion, fila.rporcentajeganacia);
    END IF;
    RETURN fila;
    END;
    $function$
