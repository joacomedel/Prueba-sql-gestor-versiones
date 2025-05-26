CREATE OR REPLACE FUNCTION public.insertarccrelacionclientecomprobanteventa(fila relacionclientecomprobanteventa)
 RETURNS relacionclientecomprobanteventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.relacionclientecomprobanteventacc:= current_timestamp;
    UPDATE sincro.relacionclientecomprobanteventa SET idcondicioniva= fila.idcondicioniva, idtipo= fila.idtipo, relacionclientecomprobanteventacc= fila.relacionclientecomprobanteventacc WHERE idcondicioniva= fila.idcondicioniva AND idtipo= fila.idtipo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.relacionclientecomprobanteventa(idcondicioniva, idtipo, relacionclientecomprobanteventacc) VALUES (fila.idcondicioniva, fila.idtipo, fila.relacionclientecomprobanteventacc);
    END IF;
    RETURN fila;
    END;
    $function$
