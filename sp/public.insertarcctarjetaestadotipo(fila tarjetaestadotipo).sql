CREATE OR REPLACE FUNCTION public.insertarcctarjetaestadotipo(fila tarjetaestadotipo)
 RETURNS tarjetaestadotipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tarjetaestadotipocc:= current_timestamp;
    UPDATE sincro.tarjetaestadotipo SET idestadotipo= fila.idestadotipo, tarjetaestadotipocc= fila.tarjetaestadotipocc, tetdescripcion= fila.tetdescripcion WHERE idestadotipo= fila.idestadotipo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.tarjetaestadotipo(idestadotipo, tarjetaestadotipocc, tetdescripcion) VALUES (fila.idestadotipo, fila.tarjetaestadotipocc, fila.tetdescripcion);
    END IF;
    RETURN fila;
    END;
    $function$
