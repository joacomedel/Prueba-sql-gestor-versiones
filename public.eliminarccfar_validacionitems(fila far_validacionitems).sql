CREATE OR REPLACE FUNCTION public.eliminarccfar_validacionitems(fila far_validacionitems)
 RETURNS far_validacionitems
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_validacionitemscc:= current_timestamp;
    delete from sincro.far_validacionitems WHERE idcentrovalidacionitem= fila.idcentrovalidacionitem AND idvalidacionitem= fila.idvalidacionitem AND TRUE;
    RETURN fila;
    END;
    $function$
