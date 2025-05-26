CREATE OR REPLACE FUNCTION public.insertarccordconsulta(fila ordconsulta)
 RETURNS ordconsulta
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordconsultacc:= current_timestamp;
    UPDATE sincro.ordconsulta SET centro= fila.centro, idplancovertura= fila.idplancovertura, nroorden= fila.nroorden, ordconsultacc= fila.ordconsultacc WHERE centro= fila.centro AND nroorden= fila.nroorden AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordconsulta(centro, idplancovertura, nroorden, ordconsultacc) VALUES (fila.centro, fila.idplancovertura, fila.nroorden, fila.ordconsultacc);
    END IF;
    RETURN fila;
    END;
    $function$
