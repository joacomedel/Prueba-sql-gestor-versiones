CREATE OR REPLACE FUNCTION public.insertarccfar_remito(fila far_remito)
 RETURNS far_remito
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_remitocc:= current_timestamp;
    UPDATE sincro.far_remito SET centro= fila.centro, far_remitocc= fila.far_remitocc, idremito= fila.idremito, rfechaingreso= fila.rfechaingreso WHERE centro= fila.centro AND idremito= fila.idremito AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_remito(centro, far_remitocc, idremito, rfechaingreso) VALUES (fila.centro, fila.far_remitocc, fila.idremito, fila.rfechaingreso);
    END IF;
    RETURN fila;
    END;
    $function$
