CREATE OR REPLACE FUNCTION public.insertarccfar_liquidacionitemestado(fila far_liquidacionitemestado)
 RETURNS far_liquidacionitemestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacionitemestadocc:= current_timestamp;
    UPDATE sincro.far_liquidacionitemestado SET liedescripcion= fila.liedescripcion, idcentroliquidacionitemestado= fila.idcentroliquidacionitemestado, far_liquidacionitemestadocc= fila.far_liquidacionitemestadocc, idestadotipo= fila.idestadotipo, liefechafin= fila.liefechafin, idcentroliquidacionitem= fila.idcentroliquidacionitem, liefechaini= fila.liefechaini, idliquidacionitem= fila.idliquidacionitem, idliquidacionitemestado= fila.idliquidacionitemestado WHERE idliquidacionitemestado= fila.idliquidacionitemestado AND idestadotipo= fila.idestadotipo AND idcentroliquidacionitem= fila.idcentroliquidacionitem AND idliquidacionitem= fila.idliquidacionitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_liquidacionitemestado(liedescripcion, idcentroliquidacionitemestado, far_liquidacionitemestadocc, idestadotipo, liefechafin, idcentroliquidacionitem, liefechaini, idliquidacionitem, idliquidacionitemestado) VALUES (fila.liedescripcion, fila.idcentroliquidacionitemestado, fila.far_liquidacionitemestadocc, fila.idestadotipo, fila.liefechafin, fila.idcentroliquidacionitem, fila.liefechaini, fila.idliquidacionitem, fila.idliquidacionitemestado);
    END IF;
    RETURN fila;
    END;
    $function$
