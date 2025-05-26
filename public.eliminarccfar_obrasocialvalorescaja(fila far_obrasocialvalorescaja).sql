CREATE OR REPLACE FUNCTION public.eliminarccfar_obrasocialvalorescaja(fila far_obrasocialvalorescaja)
 RETURNS far_obrasocialvalorescaja
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_obrasocialvalorescajacc:= current_timestamp;
    delete from sincro.far_obrasocialvalorescaja WHERE idobrasocial= fila.idobrasocial AND idvalorescaja= fila.idvalorescaja AND TRUE;
    RETURN fila;
    END;
    $function$
