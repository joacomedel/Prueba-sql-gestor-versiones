CREATE OR REPLACE FUNCTION public.insertarccprestadorconfig(fila prestadorconfig)
 RETURNS prestadorconfig
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.prestadorconfigcc:= current_timestamp;
    UPDATE sincro.prestadorconfig SET pcgastodirfarm= fila.pcgastodirfarm, idprestador= fila.idprestador, idcentroprestadorconfig= fila.idcentroprestadorconfig, prestadorconfigcc= fila.prestadorconfigcc, idprestadorconfig= fila.idprestadorconfig, pcgastodirosu= fila.pcgastodirosu WHERE idprestadorconfig= fila.idprestadorconfig AND idcentroprestadorconfig= fila.idcentroprestadorconfig AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.prestadorconfig(pcgastodirfarm, idprestador, idcentroprestadorconfig, prestadorconfigcc, idprestadorconfig, pcgastodirosu) VALUES (fila.pcgastodirfarm, fila.idprestador, fila.idcentroprestadorconfig, fila.prestadorconfigcc, fila.idprestadorconfig, fila.pcgastodirosu);
    END IF;
    RETURN fila;
    END;
    $function$
