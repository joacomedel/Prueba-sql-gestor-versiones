CREATE OR REPLACE FUNCTION public.insertarccusuarioconfiguracion(fila usuarioconfiguracion)
 RETURNS usuarioconfiguracion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.usuarioconfiguracioncc:= current_timestamp;
    UPDATE sincro.usuarioconfiguracion SET ucactivo= fila.ucactivo, dni= fila.dni, usuarioconfiguracioncc= fila.usuarioconfiguracioncc WHERE dni= fila.dni AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.usuarioconfiguracion(ucactivo, dni, usuarioconfiguracioncc) VALUES (fila.ucactivo, fila.dni, fila.usuarioconfiguracioncc);
    END IF;
    RETURN fila;
    END;
    $function$
