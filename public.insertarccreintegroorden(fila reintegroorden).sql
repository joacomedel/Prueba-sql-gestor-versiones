CREATE OR REPLACE FUNCTION public.insertarccreintegroorden(fila reintegroorden)
 RETURNS reintegroorden
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegroordencc:= current_timestamp;
    UPDATE sincro.reintegroorden SET anio= fila.anio, centro= fila.centro, centropresupuesto= fila.centropresupuesto, idcentroregional= fila.idcentroregional, nroorden= fila.nroorden, nroreintegro= fila.nroreintegro, ordenpresupuesto= fila.ordenpresupuesto, reintegroordencc= fila.reintegroordencc, tipo= fila.tipo WHERE centro= fila.centro AND nroorden= fila.nroorden AND tipo= fila.tipo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.reintegroorden(anio, centro, centropresupuesto, idcentroregional, nroorden, nroreintegro, ordenpresupuesto, reintegroordencc, tipo) VALUES (fila.anio, fila.centro, fila.centropresupuesto, fila.idcentroregional, fila.nroorden, fila.nroreintegro, fila.ordenpresupuesto, fila.reintegroordencc, fila.tipo);
    END IF;
    RETURN fila;
    END;
    $function$
