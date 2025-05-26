CREATE OR REPLACE FUNCTION public.eliminarccfar_remitoestadotipo(fila far_remitoestadotipo)
 RETURNS far_remitoestadotipo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_remitoestadotipocc:= current_timestamp;
    delete from sincro.far_remitoestadotipo WHERE idremitoestadotipo= fila.idremitoestadotipo AND TRUE;
    RETURN fila;
    END;
    $function$
