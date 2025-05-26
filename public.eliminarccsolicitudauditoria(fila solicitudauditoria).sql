CREATE OR REPLACE FUNCTION public.eliminarccsolicitudauditoria(fila solicitudauditoria)
 RETURNS solicitudauditoria
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.solicitudauditoriacc:= current_timestamp;
    delete from sincro.solicitudauditoria WHERE idcentrosolicitudauditoria= fila.idcentrosolicitudauditoria AND idsolicitudauditoria= fila.idsolicitudauditoria AND TRUE;
    RETURN fila;
    END;
    $function$
