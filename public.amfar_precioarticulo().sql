CREATE OR REPLACE FUNCTION public.amfar_precioarticulo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_precioarticulo(NEW);
        return NEW;
    END;
    $function$
