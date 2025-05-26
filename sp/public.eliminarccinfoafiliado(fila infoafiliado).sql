CREATE OR REPLACE FUNCTION public.eliminarccinfoafiliado(fila infoafiliado)
 RETURNS infoafiliado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.infoafiliadocc:= current_timestamp;
    delete from sincro.infoafiliado WHERE idinfoafiliado= fila.idinfoafiliado AND idcentroinfoafiliado= fila.idcentroinfoafiliado AND TRUE;
    RETURN fila;
    END;
    $function$
