CREATE OR REPLACE FUNCTION public.eliminarccdocumentoestado(fila documentoestado)
 RETURNS documentoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.documentoestadocc:= current_timestamp;
    delete from sincro.documentoestado WHERE iddocumentoestado= fila.iddocumentoestado AND idcentrodocumentoestado= fila.idcentrodocumentoestado AND TRUE;
    RETURN fila;
    END;
    $function$
