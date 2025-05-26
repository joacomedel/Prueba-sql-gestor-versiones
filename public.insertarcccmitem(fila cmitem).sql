CREATE OR REPLACE FUNCTION public.insertarcccmitem(fila cmitem)
 RETURNS cmitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cmitemcc:= current_timestamp;
    UPDATE sincro.cmitem SET cmicantidad= fila.cmicantidad, cmimporte= fila.cmimporte, cmitemcc= fila.cmitemcc, idcmitem= fila.idcmitem, idcompramedicamento= fila.idcompramedicamento, idformas= fila.idformas, idmonodroga= fila.idmonodroga, mnroregistro= fila.mnroregistro WHERE idcmitem= fila.idcmitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cmitem(cmicantidad, cmimporte, cmitemcc, idcmitem, idcompramedicamento, idformas, idmonodroga, mnroregistro) VALUES (fila.cmicantidad, fila.cmimporte, fila.cmitemcc, fila.idcmitem, fila.idcompramedicamento, fila.idformas, fila.idmonodroga, fila.mnroregistro);
    END IF;
    RETURN fila;
    END;
    $function$
