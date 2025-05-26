CREATE OR REPLACE FUNCTION public.eliminarccfar_remitoestado(fila far_remitoestado)
 RETURNS far_remitoestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_remitoestadocc:= current_timestamp;
    delete from sincro.far_remitoestado WHERE centrocambioestado= fila.centrocambioestado AND idremitoestado= fila.idremitoestado AND TRUE;
    RETURN fila;
    END;
    $function$
