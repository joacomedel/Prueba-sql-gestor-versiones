CREATE OR REPLACE FUNCTION public.aerecetarioconvenio()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccrecetarioconvenio(OLD);
        return OLD;
    END;
    $function$
