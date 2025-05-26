CREATE OR REPLACE FUNCTION public.eliminarccsolicitudauditoriaitem(fila solicitudauditoriaitem)
 RETURNS solicitudauditoriaitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.solicitudauditoriaitemcc:= current_timestamp;
    delete from sincro.solicitudauditoriaitem WHERE idsolicitudauditoriaitem= fila.idsolicitudauditoriaitem AND idcentrosolicitudauditoriaitem= fila.idcentrosolicitudauditoriaitem AND TRUE;
    RETURN fila;
    END;
    $function$
