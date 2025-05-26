CREATE OR REPLACE FUNCTION public.insertarcccuentashistorico(fila cuentashistorico)
 RETURNS cuentashistorico
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentashistoricocc:= current_timestamp;
    UPDATE sincro.cuentashistorico SET chcbufin= fila.chcbufin, chcbuini= fila.chcbuini, chdigitoverificador= fila.chdigitoverificador, chfechafin= fila.chfechafin, chfechainicio= fila.chfechainicio, chidusuario= fila.chidusuario, chnrobanco= fila.chnrobanco, chnrocuenta= fila.chnrocuenta, chnrosucursal= fila.chnrosucursal, chtipocuenta= fila.chtipocuenta, cuentashistoricocc= fila.cuentashistoricocc, idcentrocuentashistorico= fila.idcentrocuentashistorico, idcuentashistorico= fila.idcuentashistorico, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc WHERE idcuentashistorico= fila.idcuentashistorico AND idcentrocuentashistorico= fila.idcentrocuentashistorico AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cuentashistorico(chcbufin, chcbuini, chdigitoverificador, chfechafin, chfechainicio, chidusuario, chnrobanco, chnrocuenta, chnrosucursal, chtipocuenta, cuentashistoricocc, idcentrocuentashistorico, idcuentashistorico, nrodoc, tipodoc) VALUES (fila.chcbufin, fila.chcbuini, fila.chdigitoverificador, fila.chfechafin, fila.chfechainicio, fila.chidusuario, fila.chnrobanco, fila.chnrocuenta, fila.chnrosucursal, fila.chtipocuenta, fila.cuentashistoricocc, fila.idcentrocuentashistorico, fila.idcuentashistorico, fila.nrodoc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
