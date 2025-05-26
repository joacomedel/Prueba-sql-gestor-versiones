CREATE OR REPLACE FUNCTION public.amfar_articulo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_articulo(NEW);
        return NEW;
    END;
    $function$
