CREATE OR REPLACE FUNCTION public.insertarccdocumentoestado(fila documentoestado)
 RETURNS documentoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.documentoestadocc:= current_timestamp;
    UPDATE sincro.documentoestado SET iddocumento= fila.iddocumento, idcentrodocumento= fila.idcentrodocumento, iddocumentoestado= fila.iddocumentoestado, dofecha= fila.dofecha, dedescripcion= fila.dedescripcion, documentoestadocc= fila.documentoestadocc, iddocumentoestadotipo= fila.iddocumentoestadotipo, defechafin= fila.defechafin, idcentrodocumentoestado= fila.idcentrodocumentoestado, defechaini= fila.defechaini WHERE iddocumentoestado= fila.iddocumentoestado AND idcentrodocumentoestado= fila.idcentrodocumentoestado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.documentoestado(iddocumento, idcentrodocumento, iddocumentoestado, dofecha, dedescripcion, documentoestadocc, iddocumentoestadotipo, defechafin, idcentrodocumentoestado, defechaini) VALUES (fila.iddocumento, fila.idcentrodocumento, fila.iddocumentoestado, fila.dofecha, fila.dedescripcion, fila.documentoestadocc, fila.iddocumentoestadotipo, fila.defechafin, fila.idcentrodocumentoestado, fila.defechaini);
    END IF;
    RETURN fila;
    END;
    $function$
