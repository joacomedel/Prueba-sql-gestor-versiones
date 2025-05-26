CREATE OR REPLACE FUNCTION public.eliminarccanticipo(fila anticipo)
 RETURNS anticipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.anticipocc:= current_timestamp;
    delete from sincro.anticipo WHERE nroanticipo= fila.nroanticipo AND anio= fila.anio AND idcentroregional= fila.idcentroregional AND TRUE;
    RETURN fila;
    END;
    $function$
