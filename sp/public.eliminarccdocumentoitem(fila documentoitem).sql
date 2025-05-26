CREATE OR REPLACE FUNCTION public.eliminarccdocumentoitem(fila documentoitem)
 RETURNS documentoitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.documentoitemcc:= current_timestamp;
    delete from sincro.documentoitem WHERE idcentrodocumentoitem= fila.idcentrodocumentoitem AND iddocumentoitem= fila.iddocumentoitem AND TRUE;
    RETURN fila;
    END;
    $function$
