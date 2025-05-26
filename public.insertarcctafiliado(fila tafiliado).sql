CREATE OR REPLACE FUNCTION public.insertarcctafiliado(fila tafiliado)
 RETURNS tafiliado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tafiliadocc:= current_timestamp;
    UPDATE sincro.tafiliado SET barratemp= fila.barratemp, benef= fila.benef, cargo= fila.cargo, feinlab= fila.feinlab, finlab= fila.finlab, idafiliado= fila.idafiliado, legajo= fila.legajo, nrodoc= fila.nrodoc, tafiliadocc= fila.tafiliadocc, tipoafil= fila.tipoafil, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.tafiliado(barratemp, benef, cargo, feinlab, finlab, idafiliado, legajo, nrodoc, tafiliadocc, tipoafil, tipodoc) VALUES (fila.barratemp, fila.benef, fila.cargo, fila.feinlab, fila.finlab, fila.idafiliado, fila.legajo, fila.nrodoc, fila.tafiliadocc, fila.tipoafil, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
