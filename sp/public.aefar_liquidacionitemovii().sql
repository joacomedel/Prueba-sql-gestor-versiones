CREATE OR REPLACE FUNCTION public.aefar_liquidacionitemovii()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_liquidacionitemovii(OLD);
        return OLD;
    END;
    $function$
