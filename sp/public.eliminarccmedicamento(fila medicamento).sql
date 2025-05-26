CREATE OR REPLACE FUNCTION public.eliminarccmedicamento(fila medicamento)
 RETURNS medicamento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.medicamentocc:= current_timestamp;
    delete from sincro.medicamento WHERE mnroregistro= fila.mnroregistro AND nomenclado= fila.nomenclado AND TRUE;
    RETURN fila;
    END;
    $function$
