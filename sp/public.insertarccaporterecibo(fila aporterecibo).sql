CREATE OR REPLACE FUNCTION public.insertarccaporterecibo(fila aporterecibo)
 RETURNS aporterecibo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aporterecibocc:= current_timestamp;
    UPDATE sincro.aporterecibo SET aporterecibocc= fila.aporterecibocc, centro= fila.centro, idaporte= fila.idaporte, idcentroregionaluso= fila.idcentroregionaluso, idrecibo= fila.idrecibo WHERE idaporte= fila.idaporte AND idcentroregionaluso= fila.idcentroregionaluso AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.aporterecibo(aporterecibocc, centro, idaporte, idcentroregionaluso, idrecibo) VALUES (fila.aporterecibocc, fila.centro, fila.idaporte, fila.idcentroregionaluso, fila.idrecibo);
    END IF;
    RETURN fila;
    END;
    $function$
