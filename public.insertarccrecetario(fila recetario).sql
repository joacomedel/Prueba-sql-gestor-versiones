CREATE OR REPLACE FUNCTION public.insertarccrecetario(fila recetario)
 RETURNS recetario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recetariocc:= current_timestamp;
    UPDATE sincro.recetario SET anio= fila.anio, asi= fila.asi, centro= fila.centro, fechaemision= fila.fechaemision, fechauso= fila.fechauso, gratuito= fila.gratuito, idfarmacia= fila.idfarmacia, idplancovertura= fila.idplancovertura, idprestador= fila.idprestador, nrodoc= fila.nrodoc, nrorecetario= fila.nrorecetario, nroregistro= fila.nroregistro, recetariocc= fila.recetariocc, tipodoc= fila.tipodoc WHERE centro= fila.centro AND nrorecetario= fila.nrorecetario AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recetario(anio, asi, centro, fechaemision, fechauso, gratuito, idfarmacia, idplancovertura, idprestador, nrodoc, nrorecetario, nroregistro, recetariocc, tipodoc) VALUES (fila.anio, fila.asi, fila.centro, fila.fechaemision, fila.fechauso, fila.gratuito, fila.idfarmacia, fila.idplancovertura, fila.idprestador, fila.nrodoc, fila.nrorecetario, fila.nroregistro, fila.recetariocc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
