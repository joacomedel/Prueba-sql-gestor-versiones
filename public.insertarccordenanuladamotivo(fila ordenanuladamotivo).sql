CREATE OR REPLACE FUNCTION public.insertarccordenanuladamotivo(fila ordenanuladamotivo)
 RETURNS ordenanuladamotivo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenanuladamotivocc:= current_timestamp;
    UPDATE sincro.ordenanuladamotivo SET centro= fila.centro, nroorden= fila.nroorden, ordenanuladamotivocc= fila.ordenanuladamotivocc, idmotivoanulacionorden= fila.idmotivoanulacionorden WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenanuladamotivo(centro, nroorden, ordenanuladamotivocc, idmotivoanulacionorden) VALUES (fila.centro, fila.nroorden, fila.ordenanuladamotivocc, fila.idmotivoanulacionorden);
    END IF;
    RETURN fila;
    END;
    $function$
