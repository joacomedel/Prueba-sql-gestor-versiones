CREATE OR REPLACE FUNCTION public.insertarccanticipo(fila anticipo)
 RETURNS anticipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.anticipocc:= current_timestamp;
    UPDATE sincro.anticipo SET acentro= fila.acentro, afechaingreso= fila.afechaingreso, aimporte= fila.aimporte, aimporterestante= fila.aimporterestante, anio= fila.anio, anroorden= fila.anroorden, anticipocc= fila.anticipocc, idcentroordenpago= fila.idcentroordenpago, idcentroregional= fila.idcentroregional, nroanticipo= fila.nroanticipo, nrocuenta= fila.nrocuenta, nrodoc= fila.nrodoc, nrooperacion= fila.nrooperacion, nroordenpago= fila.nroordenpago, tipocuenta= fila.tipocuenta, tipodoc= fila.tipodoc, tipoformapago= fila.tipoformapago WHERE nroanticipo= fila.nroanticipo AND anio= fila.anio AND idcentroregional= fila.idcentroregional AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.anticipo(acentro, afechaingreso, aimporte, aimporterestante, anio, anroorden, anticipocc, idcentroordenpago, idcentroregional, nroanticipo, nrocuenta, nrodoc, nrooperacion, nroordenpago, tipocuenta, tipodoc, tipoformapago) VALUES (fila.acentro, fila.afechaingreso, fila.aimporte, fila.aimporterestante, fila.anio, fila.anroorden, fila.anticipocc, fila.idcentroordenpago, fila.idcentroregional, fila.nroanticipo, fila.nrocuenta, fila.nrodoc, fila.nrooperacion, fila.nroordenpago, fila.tipocuenta, fila.tipodoc, fila.tipoformapago);
    END IF;
    RETURN fila;
    END;
    $function$
