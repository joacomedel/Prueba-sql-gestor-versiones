CREATE OR REPLACE FUNCTION public.insertarcccuentas(fila cuentas)
 RETURNS cuentas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentascc:= current_timestamp;
    UPDATE sincro.cuentas SET cbufin= fila.cbufin, cbuini= fila.cbuini, cemail= fila.cemail, cuentascc= fila.cuentascc, cufechafin= fila.cufechafin, cufechainicio= fila.cufechainicio, cuidusuario= fila.cuidusuario, digitoverificador= fila.digitoverificador, nrobanco= fila.nrobanco, nrocuenta= fila.nrocuenta, nrodoc= fila.nrodoc, nrosucursal= fila.nrosucursal, tipocuenta= fila.tipocuenta, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND cufechainicio= fila.cufechainicio AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cuentas(cbufin, cbuini, cemail, cuentascc, cufechafin, cufechainicio, cuidusuario, digitoverificador, nrobanco, nrocuenta, nrodoc, nrosucursal, tipocuenta, tipodoc) VALUES (fila.cbufin, fila.cbuini, fila.cemail, fila.cuentascc, fila.cufechafin, fila.cufechainicio, fila.cuidusuario, fila.digitoverificador, fila.nrobanco, fila.nrocuenta, fila.nrodoc, fila.nrosucursal, fila.tipocuenta, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
