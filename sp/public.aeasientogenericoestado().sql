CREATE OR REPLACE FUNCTION public.aeasientogenericoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccasientogenericoestado(OLD);
        return OLD;
    END;
    $function$
