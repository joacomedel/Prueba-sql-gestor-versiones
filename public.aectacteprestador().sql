CREATE OR REPLACE FUNCTION public.aectacteprestador()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccctacteprestador(OLD);
        return OLD;
    END;
    $function$
