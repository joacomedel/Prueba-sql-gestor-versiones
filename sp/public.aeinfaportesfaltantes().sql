CREATE OR REPLACE FUNCTION public.aeinfaportesfaltantes()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinfaportesfaltantes(OLD);
        return OLD;
    END;
    $function$
