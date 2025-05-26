CREATE OR REPLACE FUNCTION public.eliminarccfar_remitoitem(fila far_remitoitem)
 RETURNS far_remitoitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_remitoitemcc:= current_timestamp;
    delete from sincro.far_remitoitem WHERE idcentroremitoitem= fila.idcentroremitoitem AND idremitoitem= fila.idremitoitem AND TRUE;
    RETURN fila;
    END;
    $function$
