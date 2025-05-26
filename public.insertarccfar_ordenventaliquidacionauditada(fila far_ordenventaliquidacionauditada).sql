CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventaliquidacionauditada(fila far_ordenventaliquidacionauditada)
 RETURNS far_ordenventaliquidacionauditada
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaliquidacionauditadacc:= current_timestamp;
    UPDATE sincro.far_ordenventaliquidacionauditada SET anio= fila.anio, centro= fila.centro, centroauditado= fila.centroauditado, far_ordenventaliquidacionauditadacc= fila.far_ordenventaliquidacionauditadacc, idcentroliquidacion= fila.idcentroliquidacion, idcentroordenventaitem= fila.idcentroordenventaitem, idcentroordenventaitemimporte= fila.idcentroordenventaitemimporte, idliquidacion= fila.idliquidacion, idordenventaitem= fila.idordenventaitem, idordenventaitemimporte= fila.idordenventaitemimporte, idordenventaliquidacionauditada= fila.idordenventaliquidacionauditada, nrorecetario= fila.nrorecetario, nrorecetarioauditado= fila.nrorecetarioauditado, nroregistro= fila.nroregistro, ovlafechaaditado= fila.ovlafechaaditado, ovlagenerarecetario= fila.ovlagenerarecetario, ovlaprocesado= fila.ovlaprocesado WHERE anio= fila.anio AND idcentroliquidacion= fila.idcentroliquidacion AND idcentroordenventaitem= fila.idcentroordenventaitem AND idcentroordenventaitemimporte= fila.idcentroordenventaitemimporte AND idliquidacion= fila.idliquidacion AND idordenventaitem= fila.idordenventaitem AND idordenventaitemimporte= fila.idordenventaitemimporte AND nroregistro= fila.nroregistro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventaliquidacionauditada(anio, centro, centroauditado, far_ordenventaliquidacionauditadacc, idcentroliquidacion, idcentroordenventaitem, idcentroordenventaitemimporte, idliquidacion, idordenventaitem, idordenventaitemimporte, idordenventaliquidacionauditada, nrorecetario, nrorecetarioauditado, nroregistro, ovlafechaaditado, ovlagenerarecetario, ovlaprocesado) VALUES (fila.anio, fila.centro, fila.centroauditado, fila.far_ordenventaliquidacionauditadacc, fila.idcentroliquidacion, fila.idcentroordenventaitem, fila.idcentroordenventaitemimporte, fila.idliquidacion, fila.idordenventaitem, fila.idordenventaitemimporte, fila.idordenventaliquidacionauditada, fila.nrorecetario, fila.nrorecetarioauditado, fila.nroregistro, fila.ovlafechaaditado, fila.ovlagenerarecetario, fila.ovlaprocesado);
    END IF;
    RETURN fila;
    END;
    $function$
