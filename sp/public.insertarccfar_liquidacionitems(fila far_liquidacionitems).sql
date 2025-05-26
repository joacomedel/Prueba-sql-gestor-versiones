CREATE OR REPLACE FUNCTION public.insertarccfar_liquidacionitems(fila far_liquidacionitems)
 RETURNS far_liquidacionitems
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacionitemscc:= current_timestamp;
    UPDATE sincro.far_liquidacionitems SET far_liquidacionitemscc= fila.far_liquidacionitemscc, idcentroliquidacion= fila.idcentroliquidacion, idcentroliquidacionitem= fila.idcentroliquidacionitem, idcentroordenventa= fila.idcentroordenventa, idliquidacion= fila.idliquidacion, idliquidacionitem= fila.idliquidacionitem, idordenventa= fila.idordenventa WHERE idcentroliquidacionitem= fila.idcentroliquidacionitem AND idliquidacionitem= fila.idliquidacionitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_liquidacionitems(far_liquidacionitemscc, idcentroliquidacion, idcentroliquidacionitem, idcentroordenventa, idliquidacion, idliquidacionitem, idordenventa) VALUES (fila.far_liquidacionitemscc, fila.idcentroliquidacion, fila.idcentroliquidacionitem, fila.idcentroordenventa, fila.idliquidacion, fila.idliquidacionitem, fila.idordenventa);
    END IF;
    RETURN fila;
    END;
    $function$
