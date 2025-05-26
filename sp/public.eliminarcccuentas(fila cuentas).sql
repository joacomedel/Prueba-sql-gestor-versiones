CREATE OR REPLACE FUNCTION public.eliminarcccuentas(fila cuentas)
 RETURNS cuentas
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentascc:= current_timestamp;
    delete from sincro.cuentas WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND cufechainicio= fila.cufechainicio AND TRUE;
    RETURN fila;
    END;
    $function$
