CREATE OR REPLACE FUNCTION public.amfar_precargarpedidotraza()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_precargarpedidotraza(NEW);
        return NEW;
    END;
    $function$
