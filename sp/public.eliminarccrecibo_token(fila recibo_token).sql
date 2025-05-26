CREATE OR REPLACE FUNCTION public.eliminarccrecibo_token(fila recibo_token)
 RETURNS recibo_token
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibo_tokencc:= current_timestamp;
    delete from sincro.recibo_token WHERE idrecibo= fila.idrecibo AND centro= fila.centro AND pttoken= fila.pttoken AND TRUE;
    RETURN fila;
    END;
    $function$
