CREATE OR REPLACE FUNCTION public.insertarccmapea_certdisc_alcancecobertura_fichamedicaitem(fila mapea_certdisc_alcancecobertura_fichamedicaitem)
 RETURNS mapea_certdisc_alcancecobertura_fichamedicaitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.mapea_certdisc_alcancecobertura_fichamedicaitemcc:= current_timestamp;
    UPDATE sincro.mapea_certdisc_alcancecobertura_fichamedicaitem SET idalcancecobertura= fila.idalcancecobertura, idcentroalcancecobertura= fila.idcentroalcancecobertura, idcentrocertificadodiscapacidad= fila.idcentrocertificadodiscapacidad, idcentrofichamedicaitem= fila.idcentrofichamedicaitem, idcertdiscapacidad= fila.idcertdiscapacidad, idfichamedicaitem= fila.idfichamedicaitem, mapea_certdisc_alcancecobertura_fichamedicaitemcc= fila.mapea_certdisc_alcancecobertura_fichamedicaitemcc, mcacfmifechaingreso= fila.mcacfmifechaingreso WHERE idalcancecobertura= fila.idalcancecobertura AND idfichamedicaitem= fila.idfichamedicaitem AND idcertdiscapacidad= fila.idcertdiscapacidad AND idcentrofichamedicaitem= fila.idcentrofichamedicaitem AND idcentroalcancecobertura= fila.idcentroalcancecobertura AND idcentrocertificadodiscapacidad= fila.idcentrocertificadodiscapacidad AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.mapea_certdisc_alcancecobertura_fichamedicaitem(idalcancecobertura, idcentroalcancecobertura, idcentrocertificadodiscapacidad, idcentrofichamedicaitem, idcertdiscapacidad, idfichamedicaitem, mapea_certdisc_alcancecobertura_fichamedicaitemcc, mcacfmifechaingreso) VALUES (fila.idalcancecobertura, fila.idcentroalcancecobertura, fila.idcentrocertificadodiscapacidad, fila.idcentrofichamedicaitem, fila.idcertdiscapacidad, fila.idfichamedicaitem, fila.mapea_certdisc_alcancecobertura_fichamedicaitemcc, fila.mcacfmifechaingreso);
    END IF;
    RETURN fila;
    END;
    $function$
