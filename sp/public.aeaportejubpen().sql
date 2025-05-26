CREATE OR REPLACE FUNCTION public.aeaportejubpen()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccaportejubpen(OLD);
        return OLD;
    END;
    $function$
