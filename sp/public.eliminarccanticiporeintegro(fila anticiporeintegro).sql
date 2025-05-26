CREATE OR REPLACE FUNCTION public.eliminarccanticiporeintegro(fila anticiporeintegro)
 RETURNS anticiporeintegro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.anticiporeintegrocc:= current_timestamp;
    delete from sincro.anticiporeintegro WHERE nroanticipo= fila.nroanticipo AND anioanticipo= fila.anioanticipo AND nroreintegro= fila.nroreintegro AND anioreintegro= fila.anioreintegro AND idcentroreintegro= fila.idcentroreintegro AND idcentroanticipo= fila.idcentroanticipo AND TRUE;
    RETURN fila;
    END;
    $function$
