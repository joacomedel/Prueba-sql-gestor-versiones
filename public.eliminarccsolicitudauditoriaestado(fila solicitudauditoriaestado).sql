CREATE OR REPLACE FUNCTION public.eliminarccsolicitudauditoriaestado(fila solicitudauditoriaestado)
 RETURNS solicitudauditoriaestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.solicitudauditoriaestadocc:= current_timestamp;
    delete from sincro.solicitudauditoriaestado WHERE idcentrosolicitudauditoriaestado= fila.idcentrosolicitudauditoriaestado AND idsolicitudauditoriaestado= fila.idsolicitudauditoriaestado AND TRUE;
    RETURN fila;
    END;
    $function$
