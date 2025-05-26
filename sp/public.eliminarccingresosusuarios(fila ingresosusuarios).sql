CREATE OR REPLACE FUNCTION public.eliminarccingresosusuarios(fila ingresosusuarios)
 RETURNS ingresosusuarios
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ingresosusuarioscc:= current_timestamp;
    delete from sincro.ingresosusuarios WHERE idcentroregional= fila.idcentroregional AND idsesion= fila.idsesion AND TRUE;
    RETURN fila;
    END;
    $function$
