CREATE OR REPLACE FUNCTION public.eliminarccfar_validacionxml(fila far_validacionxml)
 RETURNS far_validacionxml
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_validacionxmlcc:= current_timestamp;
    delete from sincro.far_validacionxml WHERE idcentrovalidacionxml= fila.idcentrovalidacionxml AND idvalidacionxml= fila.idvalidacionxml AND TRUE;
    RETURN fila;
    END;
    $function$
