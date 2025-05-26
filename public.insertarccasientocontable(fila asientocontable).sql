CREATE OR REPLACE FUNCTION public.insertarccasientocontable(fila asientocontable)
 RETURNS asientocontable
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.asientocontablecc:= current_timestamp;
    UPDATE sincro.asientocontable SET asientocontablecc= fila.asientocontablecc, fechaingreso= fila.fechaingreso, idasientocontable= fila.idasientocontable, idcentroregional= fila.idcentroregional WHERE idasientocontable= fila.idasientocontable AND idcentroregional= fila.idcentroregional AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.asientocontable(asientocontablecc, fechaingreso, idasientocontable, idcentroregional) VALUES (fila.asientocontablecc, fila.fechaingreso, fila.idasientocontable, fila.idcentroregional);
    END IF;
    RETURN fila;
    END;
    $function$
