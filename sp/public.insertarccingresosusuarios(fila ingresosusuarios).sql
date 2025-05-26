CREATE OR REPLACE FUNCTION public.insertarccingresosusuarios(fila ingresosusuarios)
 RETURNS ingresosusuarios
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ingresosusuarioscc:= current_timestamp;
    UPDATE sincro.ingresosusuarios SET direccionip= fila.direccionip, idcentroregional= fila.idcentroregional, idmodulo= fila.idmodulo, idsesion= fila.idsesion, idusuario= fila.idusuario, ingresosusuarioscc= fila.ingresosusuarioscc, iniciosesion= fila.iniciosesion WHERE idcentroregional= fila.idcentroregional AND idsesion= fila.idsesion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ingresosusuarios(direccionip, idcentroregional, idmodulo, idsesion, idusuario, ingresosusuarioscc, iniciosesion) VALUES (fila.direccionip, fila.idcentroregional, fila.idmodulo, fila.idsesion, fila.idusuario, fila.ingresosusuarioscc, fila.iniciosesion);
    END IF;
    RETURN fila;
    END;
    $function$
