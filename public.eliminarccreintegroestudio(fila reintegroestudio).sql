CREATE OR REPLACE FUNCTION public.eliminarccreintegroestudio(fila reintegroestudio)
 RETURNS reintegroestudio
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegroestudiocc:= current_timestamp;
    delete from sincro.reintegroestudio WHERE idcentroregional= fila.idcentroregional AND idestudio= fila.idestudio AND idrecepcion= fila.idrecepcion AND TRUE;
    RETURN fila;
    END;
    $function$
