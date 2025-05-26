CREATE OR REPLACE FUNCTION public.insertarccdocumento(fila documento)
 RETURNS documento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.documentocc:= current_timestamp;
    UPDATE sincro.documento SET docontenido= fila.docontenido, documentocc= fila.documentocc, dofechacreacion= fila.dofechacreacion, dotitulo= fila.dotitulo, idcentrodocumento= fila.idcentrodocumento, idcentrodocumentopadre= fila.idcentrodocumentopadre, iddocumento= fila.iddocumento, iddocumentopadre= fila.iddocumentopadre WHERE idcentrodocumento= fila.idcentrodocumento AND iddocumento= fila.iddocumento AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.documento(docontenido, documentocc, dofechacreacion, dotitulo, idcentrodocumento, idcentrodocumentopadre, iddocumento, iddocumentopadre) VALUES (fila.docontenido, fila.documentocc, fila.dofechacreacion, fila.dotitulo, fila.idcentrodocumento, fila.idcentrodocumentopadre, fila.iddocumento, fila.iddocumentopadre);
    END IF;
    RETURN fila;
    END;
    $function$
