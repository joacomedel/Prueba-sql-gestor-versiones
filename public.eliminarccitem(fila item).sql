CREATE OR REPLACE FUNCTION public.eliminarccitem(fila item)
 RETURNS item
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.itemcc:= current_timestamp;
    delete from sincro.item WHERE centro= fila.centro AND iditem= fila.iditem AND TRUE;
    RETURN fila;
    END;
    $function$
