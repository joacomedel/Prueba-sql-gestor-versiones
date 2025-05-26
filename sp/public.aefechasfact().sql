CREATE OR REPLACE FUNCTION public.aefechasfact()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfechasfact(OLD);
        return OLD;
    END;
    $function$
