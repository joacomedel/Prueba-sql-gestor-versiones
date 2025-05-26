CREATE OR REPLACE FUNCTION public.eliminarcccompramedicamento(fila compramedicamento)
 RETURNS compramedicamento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.compramedicamentocc:= current_timestamp;
    delete from sincro.compramedicamento WHERE idcompramedicamento= fila.idcompramedicamento AND TRUE;
    RETURN fila;
    END;
    $function$
