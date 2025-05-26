CREATE OR REPLACE FUNCTION public.insertarccanticiporeintegro(fila anticiporeintegro)
 RETURNS anticiporeintegro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.anticiporeintegrocc:= current_timestamp;
    UPDATE sincro.anticiporeintegro SET anioanticipo= fila.anioanticipo, anioreintegro= fila.anioreintegro, anticiporeintegrocc= fila.anticiporeintegrocc, fechaasociacion= fila.fechaasociacion, idcentroanticipo= fila.idcentroanticipo, idcentroreintegro= fila.idcentroreintegro, nroanticipo= fila.nroanticipo, nroreintegro= fila.nroreintegro WHERE nroanticipo= fila.nroanticipo AND anioanticipo= fila.anioanticipo AND nroreintegro= fila.nroreintegro AND anioreintegro= fila.anioreintegro AND idcentroreintegro= fila.idcentroreintegro AND idcentroanticipo= fila.idcentroanticipo AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.anticiporeintegro(anioanticipo, anioreintegro, anticiporeintegrocc, fechaasociacion, idcentroanticipo, idcentroreintegro, nroanticipo, nroreintegro) VALUES (fila.anioanticipo, fila.anioreintegro, fila.anticiporeintegrocc, fila.fechaasociacion, fila.idcentroanticipo, fila.idcentroreintegro, fila.nroanticipo, fila.nroreintegro);
    END IF;
    RETURN fila;
    END;
    $function$
