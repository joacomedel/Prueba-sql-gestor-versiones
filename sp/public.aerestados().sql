CREATE OR REPLACE FUNCTION public.aerestados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrestados(OLD);
        return OLD;
    END;
    $function$
