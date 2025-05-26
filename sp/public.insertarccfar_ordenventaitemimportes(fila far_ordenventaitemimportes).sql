CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventaitemimportes(fila far_ordenventaitemimportes)
 RETURNS far_ordenventaitemimportes
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemimportescc:= current_timestamp;
    UPDATE sincro.far_ordenventaitemimportes SET far_ordenventaitemimportescc= fila.far_ordenventaitemimportescc, idcentroordenventaitem= fila.idcentroordenventaitem, idcentroordenventaitemimporte= fila.idcentroordenventaitemimporte, idordenventaitem= fila.idordenventaitem, idordenventaitemimporte= fila.idordenventaitemimporte, idvalorescaja= fila.idvalorescaja, oviiautorizacion= fila.oviiautorizacion, oviiidafiliadocobertura= fila.oviiidafiliadocobertura, oviiidobrasocial= fila.oviiidobrasocial, oviimonto= fila.oviimonto, oviinrodoc= fila.oviinrodoc, oviiporcentajecobertura= fila.oviiporcentajecobertura, oviitipodoc= fila.oviitipodoc WHERE idcentroordenventaitemimporte= fila.idcentroordenventaitemimporte AND idordenventaitemimporte= fila.idordenventaitemimporte AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventaitemimportes(far_ordenventaitemimportescc, idcentroordenventaitem, idcentroordenventaitemimporte, idordenventaitem, idordenventaitemimporte, idvalorescaja, oviiautorizacion, oviiidafiliadocobertura, oviiidobrasocial, oviimonto, oviinrodoc, oviiporcentajecobertura, oviitipodoc) VALUES (fila.far_ordenventaitemimportescc, fila.idcentroordenventaitem, fila.idcentroordenventaitemimporte, fila.idordenventaitem, fila.idordenventaitemimporte, fila.idvalorescaja, fila.oviiautorizacion, fila.oviiidafiliadocobertura, fila.oviiidobrasocial, fila.oviimonto, fila.oviinrodoc, fila.oviiporcentajecobertura, fila.oviitipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
