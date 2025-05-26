CREATE OR REPLACE FUNCTION public.amfar_precargarpedido()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_precargarpedido(NEW);
        return NEW;
    END;
    $function$
