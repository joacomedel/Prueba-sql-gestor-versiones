CREATE OR REPLACE FUNCTION public.aefichamedicaitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicaitem(OLD);
        return OLD;
    END;
    $function$
