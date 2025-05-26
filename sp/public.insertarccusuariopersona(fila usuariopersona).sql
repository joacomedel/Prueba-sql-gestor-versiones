CREATE OR REPLACE FUNCTION public.insertarccusuariopersona(fila usuariopersona)
 RETURNS usuariopersona
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.usuariopersonacc:= current_timestamp;
    UPDATE sincro.usuariopersona SET estadoctacte= fila.estadoctacte, fechaactualizacion= fila.fechaactualizacion, fechacambio= fila.fechacambio, idcentroregional= fila.idcentroregional, idusuario= fila.idusuario, idusuariopersona= fila.idusuariopersona, motivo= fila.motivo, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc, upfechafincambio= fila.upfechafincambio, usuariopersonacc= fila.usuariopersonacc WHERE idcentroregional= fila.idcentroregional AND idusuariopersona= fila.idusuariopersona AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.usuariopersona(estadoctacte, fechaactualizacion, fechacambio, idcentroregional, idusuario, idusuariopersona, motivo, nrodoc, tipodoc, upfechafincambio, usuariopersonacc) VALUES (fila.estadoctacte, fila.fechaactualizacion, fila.fechacambio, fila.idcentroregional, fila.idusuario, fila.idusuariopersona, fila.motivo, fila.nrodoc, fila.tipodoc, fila.upfechafincambio, fila.usuariopersonacc);
    END IF;
    RETURN fila;
    END;
    $function$
