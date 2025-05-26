CREATE OR REPLACE FUNCTION public.amfar_movimientostocktipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_movimientostocktipo(NEW);
        return NEW;
    END;
    $function$
