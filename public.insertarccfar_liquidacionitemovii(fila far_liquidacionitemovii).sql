CREATE OR REPLACE FUNCTION public.insertarccfar_liquidacionitemovii(fila far_liquidacionitemovii)
 RETURNS far_liquidacionitemovii
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_liquidacionitemoviicc:= current_timestamp;
    UPDATE sincro.far_liquidacionitemovii SET far_liquidacionitemoviicc= fila.far_liquidacionitemoviicc, idcentroliquidacionitem= fila.idcentroliquidacionitem, idcentroordenventaitem= fila.idcentroordenventaitem, idcentroordenventaitemimporte= fila.idcentroordenventaitemimporte, idliquidacionitem= fila.idliquidacionitem, idordenventaitem= fila.idordenventaitem, idordenventaitemimporte= fila.idordenventaitemimporte WHERE idcentroliquidacionitem= fila.idcentroliquidacionitem AND idcentroordenventaitem= fila.idcentroordenventaitem AND idcentroordenventaitemimporte= fila.idcentroordenventaitemimporte AND idliquidacionitem= fila.idliquidacionitem AND idordenventaitem= fila.idordenventaitem AND idordenventaitemimporte= fila.idordenventaitemimporte AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_liquidacionitemovii(far_liquidacionitemoviicc, idcentroliquidacionitem, idcentroordenventaitem, idcentroordenventaitemimporte, idliquidacionitem, idordenventaitem, idordenventaitemimporte) VALUES (fila.far_liquidacionitemoviicc, fila.idcentroliquidacionitem, fila.idcentroordenventaitem, fila.idcentroordenventaitemimporte, fila.idliquidacionitem, fila.idordenventaitem, fila.idordenventaitemimporte);
    END IF;
    RETURN fila;
    END;
    $function$
