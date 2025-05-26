CREATE OR REPLACE FUNCTION public.insertarccpagosafiliado(fila pagosafiliado)
 RETURNS pagosafiliado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.pagosafiliadocc:= current_timestamp;
    UPDATE sincro.pagosafiliado SET centro= fila.centro, idpagos= fila.idpagos, nrodoc= fila.nrodoc, pagosafiliadocc= fila.pagosafiliadocc, tipodoc= fila.tipodoc WHERE centro= fila.centro AND idpagos= fila.idpagos AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.pagosafiliado(centro, idpagos, nrodoc, pagosafiliadocc, tipodoc) VALUES (fila.centro, fila.idpagos, fila.nrodoc, fila.pagosafiliadocc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
