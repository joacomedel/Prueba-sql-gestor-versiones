CREATE OR REPLACE FUNCTION public.amcontabilidad_conciliar_asientogenericoitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccontabilidad_conciliar_asientogenericoitem(NEW);
        return NEW;
    END;
    $function$
