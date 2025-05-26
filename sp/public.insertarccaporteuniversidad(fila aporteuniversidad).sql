CREATE OR REPLACE FUNCTION public.insertarccaporteuniversidad(fila aporteuniversidad)
 RETURNS aporteuniversidad
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aporteuniversidadcc:= current_timestamp;
    UPDATE sincro.aporteuniversidad SET alicfechaingreso= fila.alicfechaingreso, anio= fila.anio, aportelicsinhab= fila.aportelicsinhab, aporteuniversidadcc= fila.aporteuniversidadcc, barra= fila.barra, cancelado= fila.cancelado, fechafinaport= fila.fechafinaport, fechainiaport= fila.fechainiaport, idaporte= fila.idaporte, idcentroregionaluso= fila.idcentroregionaluso, importe= fila.importe, mes= fila.mes, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc WHERE anio= fila.anio AND mes= fila.mes AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.aporteuniversidad(alicfechaingreso, anio, aportelicsinhab, aporteuniversidadcc, barra, cancelado, fechafinaport, fechainiaport, idaporte, idcentroregionaluso, importe, mes, nrodoc, tipodoc) VALUES (fila.alicfechaingreso, fila.anio, fila.aportelicsinhab, fila.aporteuniversidadcc, fila.barra, fila.cancelado, fila.fechafinaport, fila.fechainiaport, fila.idaporte, fila.idcentroregionaluso, fila.importe, fila.mes, fila.nrodoc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
