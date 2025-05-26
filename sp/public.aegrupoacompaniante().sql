CREATE OR REPLACE FUNCTION public.aegrupoacompaniante()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccgrupoacompaniante(OLD);
        return OLD;
    END;
    $function$
