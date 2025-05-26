CREATE OR REPLACE FUNCTION public.insertarccfar_liquidacionestado(fila far_liquidacionestado)
 RETURNS far_liquidacionestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacionestadocc:= current_timestamp;
    UPDATE sincro.far_liquidacionestado SET far_liquidacionestadocc= fila.far_liquidacionestadocc, idcentroliquidacion= fila.idcentroliquidacion, idcentroliquidacionestado= fila.idcentroliquidacionestado, idestadotipo= fila.idestadotipo, idliquidacion= fila.idliquidacion, idliquidacionestado= fila.idliquidacionestado, lefechafin= fila.lefechafin, lefechaini= fila.lefechaini WHERE idcentroliquidacionestado= fila.idcentroliquidacionestado AND idliquidacionestado= fila.idliquidacionestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_liquidacionestado(far_liquidacionestadocc, idcentroliquidacion, idcentroliquidacionestado, idestadotipo, idliquidacion, idliquidacionestado, lefechafin, lefechaini) VALUES (fila.far_liquidacionestadocc, fila.idcentroliquidacion, fila.idcentroliquidacionestado, fila.idestadotipo, fila.idliquidacion, fila.idliquidacionestado, fila.lefechafin, fila.lefechaini);
    END IF;
    RETURN fila;
    END;
    $function$
