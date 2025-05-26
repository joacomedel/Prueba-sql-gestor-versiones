CREATE OR REPLACE FUNCTION public.aeasientocontable()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccasientocontable(OLD);
        return OLD;
    END;
    $function$
