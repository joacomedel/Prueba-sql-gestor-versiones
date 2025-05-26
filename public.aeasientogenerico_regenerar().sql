CREATE OR REPLACE FUNCTION public.aeasientogenerico_regenerar()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccasientogenerico_regenerar(OLD);
        return OLD;
    END;
    $function$
