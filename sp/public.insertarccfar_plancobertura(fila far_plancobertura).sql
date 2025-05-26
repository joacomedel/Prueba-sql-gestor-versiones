CREATE OR REPLACE FUNCTION public.insertarccfar_plancobertura(fila far_plancobertura)
 RETURNS far_plancobertura
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_plancoberturacc:= current_timestamp;
    UPDATE sincro.far_plancobertura SET far_plancoberturacc= fila.far_plancoberturacc, idobrasocial= fila.idobrasocial, idplancobertura= fila.idplancobertura, pcactivo= fila.pcactivo, pcdescripcion= fila.pcdescripcion, pcenlinea= fila.pcenlinea, pcporcentaje= fila.pcporcentaje WHERE idplancobertura= fila.idplancobertura AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_plancobertura(far_plancoberturacc, idobrasocial, idplancobertura, pcactivo, pcdescripcion, pcenlinea, pcporcentaje) VALUES (fila.far_plancoberturacc, fila.idobrasocial, fila.idplancobertura, fila.pcactivo, fila.pcdescripcion, fila.pcenlinea, fila.pcporcentaje);
    END IF;
    RETURN fila;
    END;
    $function$
