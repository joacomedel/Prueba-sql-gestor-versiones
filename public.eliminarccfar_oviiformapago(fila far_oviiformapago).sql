CREATE OR REPLACE FUNCTION public.eliminarccfar_oviiformapago(fila far_oviiformapago)
 RETURNS far_oviiformapago
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_oviiformapagocc:= current_timestamp;
    delete from sincro.far_oviiformapago WHERE idcentrooviiformapago= fila.idcentrooviiformapago AND idoviiformapago= fila.idoviiformapago AND TRUE;
    RETURN fila;
    END;
    $function$
