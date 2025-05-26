CREATE OR REPLACE FUNCTION public.eliminarccdocumento(fila documento)
 RETURNS documento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.documentocc:= current_timestamp;
    delete from sincro.documento WHERE idcentrodocumento= fila.idcentrodocumento AND iddocumento= fila.iddocumento AND TRUE;
    RETURN fila;
    END;
    $function$
