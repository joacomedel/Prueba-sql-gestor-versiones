CREATE OR REPLACE FUNCTION public.eliminarccfar_validacionitemsestado(fila far_validacionitemsestado)
 RETURNS far_validacionitemsestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_validacionitemsestadocc:= current_timestamp;
    delete from sincro.far_validacionitemsestado WHERE idvalidacionitemsestado= fila.idvalidacionitemsestado AND idcentrovalidacionitemsestado= fila.idcentrovalidacionitemsestado AND TRUE;
    RETURN fila;
    END;
    $function$
