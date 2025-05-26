CREATE OR REPLACE FUNCTION public.eliminarccconfigurabandejaimpresion(fila configurabandejaimpresion)
 RETURNS configurabandejaimpresion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.configurabandejaimpresioncc:= current_timestamp;
    delete from sincro.configurabandejaimpresion WHERE idbandejaimpresion= fila.idbandejaimpresion AND TRUE;
    RETURN fila;
    END;
    $function$
