CREATE OR REPLACE FUNCTION public.insertarccreintegro(fila reintegro)
 RETURNS reintegro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.reintegrocc:= current_timestamp;
    UPDATE sincro.reintegro SET anio= fila.anio, idcentroordenpago= fila.idcentroordenpago, idcentrorecepcion= fila.idcentrorecepcion, idcentroregional= fila.idcentroregional, idrecepcion= fila.idrecepcion, nrocuenta= fila.nrocuenta, nrodoc= fila.nrodoc, nrooperacion= fila.nrooperacion, nroordenpago= fila.nroordenpago, nroreintegro= fila.nroreintegro, reintegrocc= fila.reintegrocc, rfechaingreso= fila.rfechaingreso, rimporte= fila.rimporte, tipocuenta= fila.tipocuenta, tipodoc= fila.tipodoc, tipoformapago= fila.tipoformapago WHERE anio= fila.anio AND idcentroregional= fila.idcentroregional AND nroreintegro= fila.nroreintegro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.reintegro(anio, idcentroordenpago, idcentrorecepcion, idcentroregional, idrecepcion, nrocuenta, nrodoc, nrooperacion, nroordenpago, nroreintegro, reintegrocc, rfechaingreso, rimporte, tipocuenta, tipodoc, tipoformapago) VALUES (fila.anio, fila.idcentroordenpago, fila.idcentrorecepcion, fila.idcentroregional, fila.idrecepcion, fila.nrocuenta, fila.nrodoc, fila.nrooperacion, fila.nroordenpago, fila.nroreintegro, fila.reintegrocc, fila.rfechaingreso, fila.rimporte, fila.tipocuenta, fila.tipodoc, fila.tipoformapago);
    END IF;
    RETURN fila;
    END;
    $function$
