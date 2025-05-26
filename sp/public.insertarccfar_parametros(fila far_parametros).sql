CREATE OR REPLACE FUNCTION public.insertarccfar_parametros(fila far_parametros)
 RETURNS far_parametros
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_parametroscc:= current_timestamp;
    UPDATE sincro.far_parametros SET far_parametroscc= fila.far_parametroscc, idparametro= fila.idparametro, pardescripcion= fila.pardescripcion, partipo= fila.partipo WHERE idparametro= fila.idparametro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_parametros(far_parametroscc, idparametro, pardescripcion, partipo) VALUES (fila.far_parametroscc, fila.idparametro, fila.pardescripcion, fila.partipo);
    END IF;
    RETURN fila;
    END;
    $function$
