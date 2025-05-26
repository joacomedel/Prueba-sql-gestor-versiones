CREATE OR REPLACE FUNCTION public.insertarccfechasfact(fila fechasfact)
 RETURNS fechasfact
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fechasfactcc:= current_timestamp;
    UPDATE sincro.fechasfact SET idcentroregional= fila.idcentroregional, fechasfactcc= fila.fechasfactcc, fechainicio= fila.fechainicio, fechafin= fila.fechafin, idrecepcion= fila.idrecepcion WHERE fechafin= fila.fechafin AND idrecepcion= fila.idrecepcion AND fechainicio= fila.fechainicio AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fechasfact(idcentroregional, fechasfactcc, fechainicio, fechafin, idrecepcion) VALUES (fila.idcentroregional, fila.fechasfactcc, fila.fechainicio, fila.fechafin, fila.idrecepcion);
    END IF;
    RETURN fila;
    END;
    $function$
