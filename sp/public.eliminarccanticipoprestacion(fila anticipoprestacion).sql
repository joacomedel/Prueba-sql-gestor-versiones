CREATE OR REPLACE FUNCTION public.eliminarccanticipoprestacion(fila anticipoprestacion)
 RETURNS anticipoprestacion
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.anticipoprestacioncc:= current_timestamp;
    delete from sincro.anticipoprestacion WHERE anio= fila.anio AND nroanticipo= fila.nroanticipo AND tipoprestacion= fila.tipoprestacion AND idcentroregional= fila.idcentroregional AND TRUE;
    RETURN fila;
    END;
    $function$
