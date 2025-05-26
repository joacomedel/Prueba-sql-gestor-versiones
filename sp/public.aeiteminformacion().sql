CREATE OR REPLACE FUNCTION public.aeiteminformacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcciteminformacion(OLD);
        return OLD;
    END;
    $function$
