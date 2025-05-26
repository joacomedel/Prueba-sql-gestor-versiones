CREATE OR REPLACE FUNCTION public.insertarccfichamedicainfomedrecetarioitem(fila fichamedicainfomedrecetarioitem)
 RETURNS fichamedicainfomedrecetarioitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicainfomedrecetarioitemcc:= current_timestamp;
    UPDATE sincro.fichamedicainfomedrecetarioitem SET centro= fila.centro, fichamedicainfomedrecetarioitemcc= fila.fichamedicainfomedrecetarioitemcc, fmimriauditor= fila.fmimriauditor, fmimricantidadaprobada= fila.fmimricantidadaprobada, fmimrifechaingreso= fila.fmimrifechaingreso, fmimrifechavto= fila.fmimrifechavto, idcentrofichamedicainfomedicamento= fila.idcentrofichamedicainfomedicamento, idcentrofichamedicainfomedrecetarioitem= fila.idcentrofichamedicainfomedrecetarioitem, idcentrorecetariotpitem= fila.idcentrorecetariotpitem, idfichamedicainfomedicamento= fila.idfichamedicainfomedicamento, idfichamedicainfomedrecetarioitem= fila.idfichamedicainfomedrecetarioitem, idprestadorprescribe= fila.idprestadorprescribe, idrecetariotpitem= fila.idrecetariotpitem, nrorecetario= fila.nrorecetario WHERE idfichamedicainfomedrecetarioitem= fila.idfichamedicainfomedrecetarioitem AND idcentrofichamedicainfomedrecetarioitem= fila.idcentrofichamedicainfomedrecetarioitem AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.fichamedicainfomedrecetarioitem(centro, fichamedicainfomedrecetarioitemcc, fmimriauditor, fmimricantidadaprobada, fmimrifechaingreso, fmimrifechavto, idcentrofichamedicainfomedicamento, idcentrofichamedicainfomedrecetarioitem, idcentrorecetariotpitem, idfichamedicainfomedicamento, idfichamedicainfomedrecetarioitem, idprestadorprescribe, idrecetariotpitem, nrorecetario) VALUES (fila.centro, fila.fichamedicainfomedrecetarioitemcc, fila.fmimriauditor, fila.fmimricantidadaprobada, fila.fmimrifechaingreso, fila.fmimrifechavto, fila.idcentrofichamedicainfomedicamento, fila.idcentrofichamedicainfomedrecetarioitem, fila.idcentrorecetariotpitem, fila.idfichamedicainfomedicamento, fila.idfichamedicainfomedrecetarioitem, fila.idprestadorprescribe, fila.idrecetariotpitem, fila.nrorecetario);
    END IF;
    RETURN fila;
    END;
    $function$
