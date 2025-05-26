CREATE OR REPLACE FUNCTION public.insertarccordenpagocontable(fila ordenpagocontable)
 RETURNS ordenpagocontable
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ordenpagocontablecc:= current_timestamp;
    UPDATE sincro.ordenpagocontable SET idcentroordenpagocontable= fila.idcentroordenpagocontable, idordenpagocontable= fila.idordenpagocontable, idordenpagocontabletipo= fila.idordenpagocontabletipo, idprestador= fila.idprestador, opcfechacreacion= fila.opcfechacreacion, opcfechaenviomultivac= fila.opcfechaenviomultivac, opcfechaingreso= fila.opcfechaingreso, opcidusuarioenviomultivac= fila.opcidusuarioenviomultivac, opcmontochequeprop= fila.opcmontochequeprop, opcmontochequetercero= fila.opcmontochequetercero, opcmontocontadootra= fila.opcmontocontadootra, opcmontoretencion= fila.opcmontoretencion, opcmontototal= fila.opcmontototal, opcobservacion= fila.opcobservacion, ordenpagocontablecc= fila.ordenpagocontablecc WHERE idordenpagocontable= fila.idordenpagocontable AND idcentroordenpagocontable= fila.idcentroordenpagocontable AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.ordenpagocontable(idcentroordenpagocontable, idordenpagocontable, idordenpagocontabletipo, idprestador, opcfechacreacion, opcfechaenviomultivac, opcfechaingreso, opcidusuarioenviomultivac, opcmontochequeprop, opcmontochequetercero, opcmontocontadootra, opcmontoretencion, opcmontototal, opcobservacion, ordenpagocontablecc) VALUES (fila.idcentroordenpagocontable, fila.idordenpagocontable, fila.idordenpagocontabletipo, fila.idprestador, fila.opcfechacreacion, fila.opcfechaenviomultivac, fila.opcfechaingreso, fila.opcidusuarioenviomultivac, fila.opcmontochequeprop, fila.opcmontochequetercero, fila.opcmontocontadootra, fila.opcmontoretencion, fila.opcmontototal, fila.opcobservacion, fila.ordenpagocontablecc);
    END IF;
    RETURN fila;
    END;
    $function$
