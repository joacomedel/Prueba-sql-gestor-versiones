CREATE OR REPLACE FUNCTION public.aeasientogenericoitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccasientogenericoitem(OLD);
        return OLD;
    END;
    $function$
