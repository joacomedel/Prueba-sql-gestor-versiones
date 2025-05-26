CREATE OR REPLACE FUNCTION public.insertarccfichamedicaemisionpendiente(fila fichamedicaemision)
 RETURNS fichamedicaemision
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaemisionpendientecc:= current_timestamp;
    UPDATE sincro.fichamedicaemisionpendiente SET fichamedicaemisionpendientecc= fila.fichamedicaemisionpendientecc, fmepcantidad= fila.fmepcantidad, fmepfecha= fila.fmepfecha, idauditoriatipo= fila.idauditoriatipo, idcapitulo= fila.idcapitulo, idcentrofichamedicaitem= fila.idcentrofichamedicaitem, idfichamedicaitem= fila.idfichamedicaitem, idnomenclador= fila.idnomenclador, idpractica= fila.idpractica, idsubcapitulo= fila.idsubcapitulo, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc, tipoprestacion= fila.tipoprestacion WHERE idauditoriatipo= fila.idauditoriatipo AND idcentrofichamedicaitem= fila.idcentrofichamedicaitem AND idfichamedicaitem= fila.idfichamedicaitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicaemisionpendiente(fichamedicaemisionpendientecc, fmepcantidad, fmepfecha, idauditoriatipo, idcapitulo, idcentrofichamedicaitem, idfichamedicaitem, idnomenclador, idpractica, idsubcapitulo, nrodoc, tipodoc, tipoprestacion) VALUES (fila.fichamedicaemisionpendientecc, fila.fmepcantidad, fila.fmepfecha, fila.idauditoriatipo, fila.idcapitulo, fila.idcentrofichamedicaitem, fila.idfichamedicaitem, fila.idnomenclador, fila.idpractica, fila.idsubcapitulo, fila.nrodoc, fila.tipodoc, fila.tipoprestacion);
    END IF;
    RETURN fila;
    END;
    $function$
