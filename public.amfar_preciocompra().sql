CREATE OR REPLACE FUNCTION public.amfar_preciocompra()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_preciocompra(NEW);
        return NEW;
    END;
    $function$
