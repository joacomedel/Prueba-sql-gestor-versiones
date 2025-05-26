CREATE OR REPLACE FUNCTION public.eliminarccsolicitudauditoria_archivos(fila solicitudauditoria_archivos)
 RETURNS solicitudauditoria_archivos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.solicitudauditoria_archivoscc:= current_timestamp;
    delete from sincro.solicitudauditoria_archivos WHERE idcentrosolicitudauditoriaarchivo= fila.idcentrosolicitudauditoriaarchivo AND idsolicitudauditoriaarchivo= fila.idsolicitudauditoriaarchivo AND TRUE;
    RETURN fila;
    END;
    $function$
