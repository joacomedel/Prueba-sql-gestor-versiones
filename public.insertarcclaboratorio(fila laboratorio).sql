CREATE OR REPLACE FUNCTION public.insertarcclaboratorio(fila laboratorio)
 RETURNS laboratorio
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.laboratoriocc:= current_timestamp;
    UPDATE sincro.laboratorio SET idlaboratorio= fila.idlaboratorio, laboratoriocc= fila.laboratoriocc, lnombre= fila.lnombre WHERE idlaboratorio= fila.idlaboratorio AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.laboratorio(idlaboratorio, laboratoriocc, lnombre) VALUES (fila.idlaboratorio, fila.laboratoriocc, fila.lnombre);
    END IF;
    RETURN fila;
    END;
    $function$
