CREATE OR REPLACE FUNCTION public.insertarccdiscpersonaborradas(fila discpersonaborradas)
 RETURNS discpersonaborradas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.discpersonaborradascc:= current_timestamp;
    UPDATE sincro.discpersonaborradas SET discpersonaborradascc= fila.discpersonaborradascc, enteemitecert= fila.enteemitecert, fechaborrado= fila.fechaborrado, fechavtodisc= fila.fechavtodisc, iddisc= fila.iddisc, iddiscpersonaborradas= fila.iddiscpersonaborradas, nrodoc= fila.nrodoc, porcentdisc= fila.porcentdisc, tipodoc= fila.tipodoc WHERE fechavtodisc= fila.fechavtodisc AND iddisc= fila.iddisc AND iddiscpersonaborradas= fila.iddiscpersonaborradas AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.discpersonaborradas(discpersonaborradascc, enteemitecert, fechaborrado, fechavtodisc, iddisc, iddiscpersonaborradas, nrodoc, porcentdisc, tipodoc) VALUES (fila.discpersonaborradascc, fila.enteemitecert, fila.fechaborrado, fila.fechavtodisc, fila.iddisc, fila.iddiscpersonaborradas, fila.nrodoc, fila.porcentdisc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
