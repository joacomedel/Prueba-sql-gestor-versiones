CREATE OR REPLACE FUNCTION public.eliminarccmapea_certdisc_alcancecobertura_fichamedicaitem(fila mapea_certdisc_alcancecobertura_fichamedicaitem)
 RETURNS mapea_certdisc_alcancecobertura_fichamedicaitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.mapea_certdisc_alcancecobertura_fichamedicaitemcc:= current_timestamp;
    delete from sincro.mapea_certdisc_alcancecobertura_fichamedicaitem WHERE idalcancecobertura= fila.idalcancecobertura AND idfichamedicaitem= fila.idfichamedicaitem AND idcertdiscapacidad= fila.idcertdiscapacidad AND idcentrofichamedicaitem= fila.idcentrofichamedicaitem AND idcentroalcancecobertura= fila.idcentroalcancecobertura AND idcentrocertificadodiscapacidad= fila.idcentrocertificadodiscapacidad AND TRUE;
    RETURN fila;
    END;
    $function$
