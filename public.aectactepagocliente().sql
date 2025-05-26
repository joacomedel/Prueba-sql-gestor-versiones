CREATE OR REPLACE FUNCTION public.aectactepagocliente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccctactepagocliente(OLD);
        return OLD;
    END;
    $function$
