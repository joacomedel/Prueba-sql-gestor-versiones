CREATE OR REPLACE FUNCTION public.insertarccfar_ordenventaestadotipo(fila far_ordenventaestadotipo)
 RETURNS far_ordenventaestadotipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaestadotipocc:= current_timestamp;
    UPDATE sincro.far_ordenventaestadotipo SET far_ordenventaestadotipocc= fila.far_ordenventaestadotipocc, idordenventaestadotipo= fila.idordenventaestadotipo, ovetdescripcion= fila.ovetdescripcion WHERE idordenventaestadotipo= fila.idordenventaestadotipo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenventaestadotipo(far_ordenventaestadotipocc, idordenventaestadotipo, ovetdescripcion) VALUES (fila.far_ordenventaestadotipocc, fila.idordenventaestadotipo, fila.ovetdescripcion);
    END IF;
    RETURN fila;
    END;
    $function$
