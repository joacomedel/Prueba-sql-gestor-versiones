CREATE OR REPLACE FUNCTION public.insertarccreclibrocon(fila reclibrocon)
 RETURNS reclibrocon
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reclibroconcc:= current_timestamp;
    UPDATE sincro.reclibrocon SET sector= fila.sector, idcentroregional= fila.idcentroregional, idrecepcion= fila.idrecepcion, numeroexpte= fila.numeroexpte, reclibroconcc= fila.reclibroconcc WHERE idcentroregional= fila.idcentroregional AND idrecepcion= fila.idrecepcion AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.reclibrocon(sector, idcentroregional, idrecepcion, numeroexpte, reclibroconcc) VALUES (fila.sector, fila.idcentroregional, fila.idrecepcion, fila.numeroexpte, fila.reclibroconcc);
    END IF;
    RETURN fila;
    END;
    $function$
