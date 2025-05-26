CREATE OR REPLACE FUNCTION public.aecontabilidad_conciliar_asientogenericoitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccontabilidad_conciliar_asientogenericoitem(OLD);
        return OLD;
    END;
    $function$
