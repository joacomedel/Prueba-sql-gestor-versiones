CREATE OR REPLACE FUNCTION public.insertarccfichamedicaitem(fila fichamedicaitem)
 RETURNS fichamedicaitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicaitemcc:= current_timestamp;
    UPDATE sincro.fichamedicaitem SET fichamedicaitemcc= fila.fichamedicaitemcc, fmicantidad= fila.fmicantidad, fmidescripcion= fila.fmidescripcion, fmifechaauditoria= fila.fmifechaauditoria, fmiidarticulo= fila.fmiidarticulo, fmiidcentroarticulo= fila.fmiidcentroarticulo, fmiidmonodroga= fila.fmiidmonodroga, fmiidplancoberturas= fila.fmiidplancoberturas, fmiobservacionauditoria= fila.fmiobservacionauditoria, fmiobservacionexpendio= fila.fmiobservacionexpendio, fmiporreintegro= fila.fmiporreintegro, idcapitulo= fila.idcapitulo, idcentrofichamedica= fila.idcentrofichamedica, idcentrofichamedicaitem= fila.idcentrofichamedicaitem, idfichamedica= fila.idfichamedica, idfichamedicaitem= fila.idfichamedicaitem, idnomenclador= fila.idnomenclador, idpractica= fila.idpractica, idprestador= fila.idprestador, idsubcapitulo= fila.idsubcapitulo, idusuario= fila.idusuario WHERE idfichamedicaitem= fila.idfichamedicaitem AND idcentrofichamedicaitem= fila.idcentrofichamedicaitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicaitem(fichamedicaitemcc, fmicantidad, fmidescripcion, fmifechaauditoria, fmiidarticulo, fmiidcentroarticulo, fmiidmonodroga, fmiidplancoberturas, fmiobservacionauditoria, fmiobservacionexpendio, fmiporreintegro, idcapitulo, idcentrofichamedica, idcentrofichamedicaitem, idfichamedica, idfichamedicaitem, idnomenclador, idpractica, idprestador, idsubcapitulo, idusuario) VALUES (fila.fichamedicaitemcc, fila.fmicantidad, fila.fmidescripcion, fila.fmifechaauditoria, fila.fmiidarticulo, fila.fmiidcentroarticulo, fila.fmiidmonodroga, fila.fmiidplancoberturas, fila.fmiobservacionauditoria, fila.fmiobservacionexpendio, fila.fmiporreintegro, fila.idcapitulo, fila.idcentrofichamedica, fila.idcentrofichamedicaitem, fila.idfichamedica, fila.idfichamedicaitem, fila.idnomenclador, fila.idpractica, fila.idprestador, fila.idsubcapitulo, fila.idusuario);
    END IF;
    RETURN fila;
    END;
    $function$
