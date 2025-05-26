CREATE OR REPLACE FUNCTION public.aeordenestados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenestados(OLD);
        return OLD;
    END;
    $function$
