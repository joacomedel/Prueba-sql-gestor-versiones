CREATE OR REPLACE FUNCTION public.aetipocliente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcctipocliente(OLD);
        return OLD;
    END;
    $function$
