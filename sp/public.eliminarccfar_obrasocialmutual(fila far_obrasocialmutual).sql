CREATE OR REPLACE FUNCTION public.eliminarccfar_obrasocialmutual(fila far_obrasocialmutual)
 RETURNS far_obrasocialmutual
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_obrasocialmutualcc:= current_timestamp;
    delete from sincro.far_obrasocialmutual WHERE idmutual= fila.idmutual AND idobrasocial= fila.idobrasocial AND TRUE;
    RETURN fila;
    END;
    $function$
