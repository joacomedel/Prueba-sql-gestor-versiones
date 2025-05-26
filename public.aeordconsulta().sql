CREATE OR REPLACE FUNCTION public.aeordconsulta()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordconsulta(OLD);
        return OLD;
    END;
    $function$
