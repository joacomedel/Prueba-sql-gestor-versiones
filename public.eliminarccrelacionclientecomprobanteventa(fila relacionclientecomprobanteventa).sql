CREATE OR REPLACE FUNCTION public.eliminarccrelacionclientecomprobanteventa(fila relacionclientecomprobanteventa)
 RETURNS relacionclientecomprobanteventa
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.relacionclientecomprobanteventacc:= current_timestamp;
    delete from sincro.relacionclientecomprobanteventa WHERE idcondicioniva= fila.idcondicioniva AND idtipo= fila.idtipo AND TRUE;
    RETURN fila;
    END;
    $function$
