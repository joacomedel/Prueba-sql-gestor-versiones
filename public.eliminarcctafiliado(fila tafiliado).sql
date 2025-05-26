CREATE OR REPLACE FUNCTION public.eliminarcctafiliado(fila tafiliado)
 RETURNS tafiliado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.tafiliadocc:= current_timestamp;
    delete from sincro.tafiliado WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
