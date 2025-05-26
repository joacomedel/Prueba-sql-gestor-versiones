CREATE OR REPLACE FUNCTION public.aeadmusuarios()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccadmusuarios(OLD);
        return OLD;
    END;
    $function$
