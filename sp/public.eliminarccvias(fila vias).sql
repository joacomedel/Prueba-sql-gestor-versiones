CREATE OR REPLACE FUNCTION public.eliminarccvias(fila vias)
 RETURNS vias
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.viascc:= current_timestamp;
    delete from sincro.vias WHERE idvias= fila.idvias AND TRUE;
    RETURN fila;
    END;
    $function$
