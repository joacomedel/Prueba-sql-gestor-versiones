CREATE OR REPLACE FUNCTION public.amfar_precioarticulosugerido()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_precioarticulosugerido(NEW);
        return NEW;
    END;
    $function$
