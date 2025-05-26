CREATE OR REPLACE FUNCTION public.aeaporteuniversidad()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccaporteuniversidad(OLD);
        return OLD;
    END;
    $function$
