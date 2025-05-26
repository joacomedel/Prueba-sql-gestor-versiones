CREATE OR REPLACE FUNCTION public.aeprestadorconvenio()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccprestadorconvenio(OLD);
        return OLD;
    END;
    $function$
