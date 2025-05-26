CREATE OR REPLACE FUNCTION public.aemonodroga()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccmonodroga(OLD);
        return OLD;
    END;
    $function$
