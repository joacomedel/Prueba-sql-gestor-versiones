CREATE OR REPLACE FUNCTION public.aerecetarioestados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecetarioestados(OLD);
        return OLD;
    END;
    $function$
