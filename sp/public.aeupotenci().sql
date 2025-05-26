CREATE OR REPLACE FUNCTION public.aeupotenci()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccupotenci(OLD);
        return OLD;
    END;
    $function$
