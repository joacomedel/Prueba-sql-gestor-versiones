CREATE OR REPLACE FUNCTION public.eliminarcccuentashistorico(fila cuentashistorico)
 RETURNS cuentashistorico
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.cuentashistoricocc:= current_timestamp;
    delete from sincro.cuentashistorico WHERE idcuentashistorico= fila.idcuentashistorico AND idcentrocuentashistorico= fila.idcentrocuentashistorico AND TRUE;
    RETURN fila;
    END;
    $function$
