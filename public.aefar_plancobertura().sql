CREATE OR REPLACE FUNCTION public.aefar_plancobertura()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_plancobertura(OLD);
        return OLD;
    END;
    $function$
