CREATE OR REPLACE FUNCTION public.eliminarccinfoafiliado_dondemostra(fila infoafiliado_dondemostra)
 RETURNS infoafiliado_dondemostra
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.infoafiliado_dondemostracc:= current_timestamp;
    delete from sincro.infoafiliado_dondemostra WHERE idcentroinfoafiliado= fila.idcentroinfoafiliado AND idinfoafiliado= fila.idinfoafiliado AND idinfoafiliadoquienmuestra= fila.idinfoafiliadoquienmuestra AND TRUE;
    RETURN fila;
    END;
    $function$
