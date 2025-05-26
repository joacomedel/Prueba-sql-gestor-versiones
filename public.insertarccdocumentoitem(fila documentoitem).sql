CREATE OR REPLACE FUNCTION public.insertarccdocumentoitem(fila documentoitem)
 RETURNS documentoitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.documentoitemcc:= current_timestamp;
    UPDATE sincro.documentoitem SET documentoitemcc= fila.documentoitemcc, idanioclave= fila.idanioclave, idcentroclave= fila.idcentroclave, idcentrodocumento= fila.idcentrodocumento, idcentrodocumentoitem= fila.idcentrodocumentoitem, idcentroordenpago= fila.idcentroordenpago, idcentroregional= fila.idcentroregional, idclave= fila.idclave, iddocumento= fila.iddocumento, iddocumentoitem= fila.iddocumentoitem, idrecepcion= fila.idrecepcion, idtipocomprobante= fila.idtipocomprobante, nroordenpago= fila.nroordenpago WHERE idcentrodocumentoitem= fila.idcentrodocumentoitem AND iddocumentoitem= fila.iddocumentoitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.documentoitem(documentoitemcc, idanioclave, idcentroclave, idcentrodocumento, idcentrodocumentoitem, idcentroordenpago, idcentroregional, idclave, iddocumento, iddocumentoitem, idrecepcion, idtipocomprobante, nroordenpago) VALUES (fila.documentoitemcc, fila.idanioclave, fila.idcentroclave, fila.idcentrodocumento, fila.idcentrodocumentoitem, fila.idcentroordenpago, fila.idcentroregional, fila.idclave, fila.iddocumento, fila.iddocumentoitem, fila.idrecepcion, fila.idtipocomprobante, fila.nroordenpago);
    END IF;
    RETURN fila;
    END;
    $function$
