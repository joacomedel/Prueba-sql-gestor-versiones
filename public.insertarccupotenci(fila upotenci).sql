CREATE OR REPLACE FUNCTION public.insertarccupotenci(fila upotenci)
 RETURNS upotenci
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.upotencicc:= current_timestamp;
    UPDATE sincro.upotenci SET idupotenci= fila.idupotenci, updescripcion= fila.updescripcion, upotencicc= fila.upotencicc WHERE idupotenci= fila.idupotenci AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.upotenci(idupotenci, updescripcion, upotencicc) VALUES (fila.idupotenci, fila.updescripcion, fila.upotencicc);
    END IF;
    RETURN fila;
    END;
    $function$
