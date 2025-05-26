CREATE OR REPLACE FUNCTION public.aefestados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfestados(OLD);
        return OLD;
    END;
    $function$
