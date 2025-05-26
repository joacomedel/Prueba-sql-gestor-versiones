CREATE OR REPLACE FUNCTION public.insertarccfar_liquidacion(fila far_liquidacion)
 RETURNS far_liquidacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacioncc:= current_timestamp;
    UPDATE sincro.far_liquidacion SET lidescripcion= fila.lidescripcion, lfechadesde= fila.lfechadesde, limporte= fila.limporte, lfechahasta= fila.lfechahasta, idobrasocial= fila.idobrasocial, nroliquidacionorigen= fila.nroliquidacionorigen, coseguro= fila.coseguro, far_liquidacioncc= fila.far_liquidacioncc, pcporcentaje= fila.pcporcentaje, lifechacreacion= fila.lifechacreacion, idliquidacion= fila.idliquidacion, idcentroliquidacion= fila.idcentroliquidacion WHERE idliquidacion= fila.idliquidacion AND idcentroliquidacion= fila.idcentroliquidacion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_liquidacion(lidescripcion, lfechadesde, limporte, lfechahasta, idobrasocial, nroliquidacionorigen, coseguro, far_liquidacioncc, pcporcentaje, lifechacreacion, idliquidacion, idcentroliquidacion) VALUES (fila.lidescripcion, fila.lfechadesde, fila.limporte, fila.lfechahasta, fila.idobrasocial, fila.nroliquidacionorigen, fila.coseguro, fila.far_liquidacioncc, fila.pcporcentaje, fila.lifechacreacion, fila.idliquidacion, fila.idcentroliquidacion);
    END IF;
    RETURN fila;
    END;
    $function$
