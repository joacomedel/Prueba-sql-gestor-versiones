CREATE OR REPLACE FUNCTION public.aebeneficiariosreciborrados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccbeneficiariosreciborrados(OLD);
        return OLD;
    END;
    $function$
