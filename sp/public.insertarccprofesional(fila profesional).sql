CREATE OR REPLACE FUNCTION public.insertarccprofesional(fila profesional)
 RETURNS profesional
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.profesionalcc:= current_timestamp;
    UPDATE sincro.profesional SET idprestador= fila.idprestador, papellido= fila.papellido, pcategoria= fila.pcategoria, pfechanac= fila.pfechanac, pfecharecibido= fila.pfecharecibido, pnombres= fila.pnombres, pnrodoc= fila.pnrodoc, pnrojubilacion= fila.pnrojubilacion, profesionalcc= fila.profesionalcc, ptipodoc= fila.ptipodoc WHERE idprestador= fila.idprestador AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.profesional(idprestador, papellido, pcategoria, pfechanac, pfecharecibido, pnombres, pnrodoc, pnrojubilacion, profesionalcc, ptipodoc) VALUES (fila.idprestador, fila.papellido, fila.pcategoria, fila.pfechanac, fila.pfecharecibido, fila.pnombres, fila.pnrodoc, fila.pnrojubilacion, fila.profesionalcc, fila.ptipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
