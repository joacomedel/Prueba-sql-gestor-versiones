CREATE OR REPLACE FUNCTION public.aebeneficiariosborrados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccbeneficiariosborrados(OLD);
        return OLD;
    END;
    $function$
