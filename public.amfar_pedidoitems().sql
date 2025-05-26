CREATE OR REPLACE FUNCTION public.amfar_pedidoitems()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_pedidoitems(NEW);
        return NEW;
    END;
    $function$
