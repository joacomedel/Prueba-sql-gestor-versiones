CREATE OR REPLACE FUNCTION public.insertarccfar_ubicacion(fila far_ubicacion)
 RETURNS far_ubicacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ubicacioncc:= current_timestamp;
    UPDATE sincro.far_ubicacion SET far_ubicacioncc= fila.far_ubicacioncc, idcentrodeposito= fila.idcentrodeposito, idcentroubicacion= fila.idcentroubicacion, iddeposito= fila.iddeposito, idubicacion= fila.idubicacion, ucomentario= fila.ucomentario, udescripcion= fila.udescripcion WHERE idcentroubicacion= fila.idcentroubicacion AND idubicacion= fila.idubicacion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_ubicacion(far_ubicacioncc, idcentrodeposito, idcentroubicacion, iddeposito, idubicacion, ucomentario, udescripcion) VALUES (fila.far_ubicacioncc, fila.idcentrodeposito, fila.idcentroubicacion, fila.iddeposito, fila.idubicacion, fila.ucomentario, fila.udescripcion);
    END IF;
    RETURN fila;
    END;
    $function$
