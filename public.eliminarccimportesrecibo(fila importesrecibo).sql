CREATE OR REPLACE FUNCTION public.eliminarccimportesrecibo(fila importesrecibo)
 RETURNS importesrecibo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.importesrecibocc:= current_timestamp;
    delete from sincro.importesrecibo WHERE centro= fila.centro AND idformapagotipos= fila.idformapagotipos AND idrecibo= fila.idrecibo AND TRUE;
    RETURN fila;
    END;
    $function$
