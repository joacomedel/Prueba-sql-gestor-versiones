CREATE OR REPLACE FUNCTION public.insertarccplancobpersona(fila plancobpersona)
 RETURNS plancobpersona
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.plancobpersonacc:= current_timestamp;
    UPDATE sincro.plancobpersona SET idplancobertura= fila.idplancobertura, idplancoberturas= fila.idplancoberturas, nrodoc= fila.nrodoc, pcpcantdias= fila.pcpcantdias, pcpdetalleinforme= fila.pcpdetalleinforme, pcpdiagnostico= fila.pcpdiagnostico, pcpfechaalta= fila.pcpfechaalta, pcpfechafin= fila.pcpfechafin, pcpfechaingreso= fila.pcpfechaingreso, pcplugarinternacion= fila.pcplugarinternacion, pcppresinforme= fila.pcppresinforme, pcpprestador= fila.pcpprestador, pcptipointernacion= fila.pcptipointernacion, plancobpersonacc= fila.plancobpersonacc, tipodoc= fila.tipodoc WHERE idplancoberturas= fila.idplancoberturas AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.plancobpersona(idplancobertura, idplancoberturas, nrodoc, pcpcantdias, pcpdetalleinforme, pcpdiagnostico, pcpfechaalta, pcpfechafin, pcpfechaingreso, pcplugarinternacion, pcppresinforme, pcpprestador, pcptipointernacion, plancobpersonacc, tipodoc) VALUES (fila.idplancobertura, fila.idplancoberturas, fila.nrodoc, fila.pcpcantdias, fila.pcpdetalleinforme, fila.pcpdiagnostico, fila.pcpfechaalta, fila.pcpfechafin, fila.pcpfechaingreso, fila.pcplugarinternacion, fila.pcppresinforme, fila.pcpprestador, fila.pcptipointernacion, fila.plancobpersonacc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
