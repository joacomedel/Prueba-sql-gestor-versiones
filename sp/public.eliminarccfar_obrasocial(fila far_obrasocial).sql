CREATE OR REPLACE FUNCTION public.eliminarccfar_obrasocial(fila far_obrasocial)
 RETURNS far_obrasocial
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_obrasocialcc:= current_timestamp;
    delete from sincro.far_obrasocial WHERE idobrasocial= fila.idobrasocial AND TRUE;
    RETURN fila;
    END;
    $function$
