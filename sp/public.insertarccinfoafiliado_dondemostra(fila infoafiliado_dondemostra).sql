CREATE OR REPLACE FUNCTION public.insertarccinfoafiliado_dondemostra(fila infoafiliado_dondemostra)
 RETURNS infoafiliado_dondemostra
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.infoafiliado_dondemostracc:= current_timestamp;
    UPDATE sincro.infoafiliado_dondemostra SET idcentroinfoafiliado= fila.idcentroinfoafiliado, idinfoafiliado= fila.idinfoafiliado, idinfoafiliadoquienmuestra= fila.idinfoafiliadoquienmuestra, infoafiliado_dondemostracc= fila.infoafiliado_dondemostracc WHERE idcentroinfoafiliado= fila.idcentroinfoafiliado AND idinfoafiliado= fila.idinfoafiliado AND idinfoafiliadoquienmuestra= fila.idinfoafiliadoquienmuestra AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.infoafiliado_dondemostra(idcentroinfoafiliado, idinfoafiliado, idinfoafiliadoquienmuestra, infoafiliado_dondemostracc) VALUES (fila.idcentroinfoafiliado, fila.idinfoafiliado, fila.idinfoafiliadoquienmuestra, fila.infoafiliado_dondemostracc);
    END IF;
    RETURN fila;
    END;
    $function$
