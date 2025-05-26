CREATE OR REPLACE FUNCTION public.aefar_movimientostocktipo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_movimientostocktipo(OLD);
        return OLD;
    END;
    $function$
