CREATE OR REPLACE FUNCTION public.eliminarcccontabilidad_conciliar_asientogenericoitem(fila contabilidad_conciliar_asientogenericoitem)
 RETURNS contabilidad_conciliar_asientogenericoitem
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.contabilidad_conciliar_asientogenericoitemcc:= current_timestamp;
    delete from sincro.contabilidad_conciliar_asientogenericoitem WHERE idcentroccasientogenericoitem= fila.idcentroccasientogenericoitem AND idccasientogenericoitem= fila.idccasientogenericoitem AND TRUE;
    RETURN fila;
    END;
    $function$
