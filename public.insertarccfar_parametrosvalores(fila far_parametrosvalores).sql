CREATE OR REPLACE FUNCTION public.insertarccfar_parametrosvalores(fila far_parametrosvalores)
 RETURNS far_parametrosvalores
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_parametrosvalorescc:= current_timestamp;
    UPDATE sincro.far_parametrosvalores SET far_parametrosvalorescc= fila.far_parametrosvalorescc, idcentroregional= fila.idcentroregional, idparametro= fila.idparametro, pvvalor= fila.pvvalor WHERE idcentroregional= fila.idcentroregional AND idparametro= fila.idparametro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_parametrosvalores(far_parametrosvalorescc, idcentroregional, idparametro, pvvalor) VALUES (fila.far_parametrosvalorescc, fila.idcentroregional, fila.idparametro, fila.pvvalor);
    END IF;
    RETURN fila;
    END;
    $function$
