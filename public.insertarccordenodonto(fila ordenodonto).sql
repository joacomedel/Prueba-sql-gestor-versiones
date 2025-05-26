CREATE OR REPLACE FUNCTION public.insertarccordenodonto(fila ordenodonto)
 RETURNS ordenodonto
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenodontocc:= current_timestamp;
    UPDATE sincro.ordenodonto SET centro= fila.centro, iditem= fila.iditem, idletradental= fila.idletradental, idpiezadental= fila.idpiezadental, idzonadental= fila.idzonadental, nroorden= fila.nroorden, ordenodontocc= fila.ordenodontocc WHERE centro= fila.centro AND iditem= fila.iditem AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenodonto(centro, iditem, idletradental, idpiezadental, idzonadental, nroorden, ordenodontocc) VALUES (fila.centro, fila.iditem, fila.idletradental, fila.idpiezadental, fila.idzonadental, fila.nroorden, fila.ordenodontocc);
    END IF;
    RETURN fila;
    END;
    $function$
