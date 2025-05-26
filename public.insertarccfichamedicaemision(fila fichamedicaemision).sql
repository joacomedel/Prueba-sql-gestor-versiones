CREATE OR REPLACE FUNCTION public.insertarccfichamedicaemision(fila fichamedicaemision)
 RETURNS fichamedicaemision
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaemisioncc:= current_timestamp;
    UPDATE sincro.fichamedicaemision SET fichamedicaemisioncc= fila.fichamedicaemisioncc, fichamedicaemisionpendientecc= fila.fichamedicaemisionpendientecc, fmefechavto= fila.fmefechavto, fmeidarticulo= fila.fmeidarticulo, fmeidcentroarticulo= fila.fmeidcentroarticulo, fmeidmonodroga= fila.fmeidmonodroga, fmeidplancoberturas= fila.fmeidplancoberturas, fmeobservacionauditoria= fila.fmeobservacionauditoria, fmeobservacionexpendio= fila.fmeobservacionexpendio, fmepcantidad= fila.fmepcantidad, fmepfecha= fila.fmepfecha, idauditoriatipo= fila.idauditoriatipo, idcapitulo= fila.idcapitulo, idcentrofichamedicaitem= fila.idcentrofichamedicaitem, idfichamedicaitem= fila.idfichamedicaitem, idnomenclador= fila.idnomenclador, idpractica= fila.idpractica, idsubcapitulo= fila.idsubcapitulo, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc, tipoprestacion= fila.tipoprestacion WHERE idauditoriatipo= fila.idauditoriatipo AND idfichamedicaitem= fila.idfichamedicaitem AND idcentrofichamedicaitem= fila.idcentrofichamedicaitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicaemision(fichamedicaemisioncc, fichamedicaemisionpendientecc, fmefechavto, fmeidarticulo, fmeidcentroarticulo, fmeidmonodroga, fmeidplancoberturas, fmeobservacionauditoria, fmeobservacionexpendio, fmepcantidad, fmepfecha, idauditoriatipo, idcapitulo, idcentrofichamedicaitem, idfichamedicaitem, idnomenclador, idpractica, idsubcapitulo, nrodoc, tipodoc, tipoprestacion) VALUES (fila.fichamedicaemisioncc, fila.fichamedicaemisionpendientecc, fila.fmefechavto, fila.fmeidarticulo, fila.fmeidcentroarticulo, fila.fmeidmonodroga, fila.fmeidplancoberturas, fila.fmeobservacionauditoria, fila.fmeobservacionexpendio, fila.fmepcantidad, fila.fmepfecha, fila.idauditoriatipo, fila.idcapitulo, fila.idcentrofichamedicaitem, fila.idfichamedicaitem, fila.idnomenclador, fila.idpractica, fila.idsubcapitulo, fila.nrodoc, fila.tipodoc, fila.tipoprestacion);
    END IF;
    RETURN fila;
    END;
    $function$
