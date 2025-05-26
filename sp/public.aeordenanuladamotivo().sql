CREATE OR REPLACE FUNCTION public.aeordenanuladamotivo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenanuladamotivo(OLD);
        return OLD;
    END;
    $function$
