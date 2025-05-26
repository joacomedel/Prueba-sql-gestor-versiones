CREATE OR REPLACE FUNCTION public.amfar_pedido()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_pedido(NEW);
        return NEW;
    END;
    $function$
