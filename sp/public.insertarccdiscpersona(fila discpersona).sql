CREATE OR REPLACE FUNCTION public.insertarccdiscpersona(fila discpersona)
 RETURNS discpersona
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.discpersonacc:= current_timestamp;
    UPDATE sincro.discpersona SET nrodoc= fila.nrodoc, discpersonacc= fila.discpersonacc, fechavtodisc= fila.fechavtodisc, porcentdisc= fila.porcentdisc, tipodoc= fila.tipodoc, iddisc= fila.iddisc, entemitecert= fila.entemitecert, idusuario= fila.idusuario WHERE iddisc= fila.iddisc AND fechavtodisc= fila.fechavtodisc AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.discpersona(nrodoc, discpersonacc, fechavtodisc, porcentdisc, tipodoc, iddisc, entemitecert, idusuario) VALUES (fila.nrodoc, fila.discpersonacc, fila.fechavtodisc, fila.porcentdisc, fila.tipodoc, fila.iddisc, fila.entemitecert, fila.idusuario);
    END IF;
    RETURN fila;
    END;
    $function$
