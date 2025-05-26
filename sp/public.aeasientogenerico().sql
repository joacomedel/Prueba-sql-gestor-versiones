CREATE OR REPLACE FUNCTION public.aeasientogenerico()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccasientogenerico(OLD);
        return OLD;
    END;
    $function$
