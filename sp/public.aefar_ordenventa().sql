CREATE OR REPLACE FUNCTION public.aefar_ordenventa()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_ordenventa(OLD);
        return OLD;
    END;
    $function$
