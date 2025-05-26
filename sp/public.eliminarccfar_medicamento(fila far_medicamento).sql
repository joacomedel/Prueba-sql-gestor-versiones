CREATE OR REPLACE FUNCTION public.eliminarccfar_medicamento(fila far_medicamento)
 RETURNS far_medicamento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_medicamentocc:= current_timestamp;
    delete from sincro.far_medicamento WHERE mnroregistro= fila.mnroregistro AND nomenclado= fila.nomenclado AND TRUE;
    RETURN fila;
    END;
    $function$
