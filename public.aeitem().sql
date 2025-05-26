CREATE OR REPLACE FUNCTION public.aeitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccitem(OLD);
        return OLD;
    END;
    $function$
