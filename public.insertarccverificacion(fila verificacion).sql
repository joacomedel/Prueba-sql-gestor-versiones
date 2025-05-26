CREATE OR REPLACE FUNCTION public.insertarccverificacion(fila verificacion)
 RETURNS verificacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.verificacioncc:= current_timestamp;
    UPDATE sincro.verificacion SET barra= fila.barra, codigo= fila.codigo, fecha= fila.fecha, nrodoc= fila.nrodoc, rango= fila.rango, verificacioncc= fila.verificacioncc WHERE codigo= fila.codigo AND fecha= fila.fecha AND nrodoc= fila.nrodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.verificacion(barra, codigo, fecha, nrodoc, rango, verificacioncc) VALUES (fila.barra, fila.codigo, fila.fecha, fila.nrodoc, fila.rango, fila.verificacioncc);
    END IF;
    RETURN fila;
    END;
    $function$
