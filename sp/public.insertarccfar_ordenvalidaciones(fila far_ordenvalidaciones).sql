CREATE OR REPLACE FUNCTION public.insertarccfar_ordenvalidaciones(fila far_ordenvalidaciones)
 RETURNS far_ordenvalidaciones
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenvalidacionescc:= current_timestamp;
    UPDATE sincro.far_ordenvalidaciones SET far_ordenvalidacionescc= fila.far_ordenvalidacionescc, fofechamodif= fila.fofechamodif, idcentroordenventa= fila.idcentroordenventa, idcentrovalidacion= fila.idcentrovalidacion, idordenventa= fila.idordenventa, idvalidacion= fila.idvalidacion WHERE idordenventa= fila.idordenventa AND idcentroordenventa= fila.idcentroordenventa AND idvalidacion= fila.idvalidacion AND idcentrovalidacion= fila.idcentrovalidacion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ordenvalidaciones(far_ordenvalidacionescc, fofechamodif, idcentroordenventa, idcentrovalidacion, idordenventa, idvalidacion) VALUES (fila.far_ordenvalidacionescc, fila.fofechamodif, fila.idcentroordenventa, fila.idcentrovalidacion, fila.idordenventa, fila.idvalidacion);
    END IF;
    RETURN fila;
    END;
    $function$
