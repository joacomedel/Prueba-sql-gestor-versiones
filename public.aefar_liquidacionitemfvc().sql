CREATE OR REPLACE FUNCTION public.aefar_liquidacionitemfvc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_liquidacionitemfvc(OLD);
        return OLD;
    END;
    $function$
