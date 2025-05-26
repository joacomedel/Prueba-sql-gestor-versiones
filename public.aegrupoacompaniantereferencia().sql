CREATE OR REPLACE FUNCTION public.aegrupoacompaniantereferencia()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccgrupoacompaniantereferencia(OLD);
        return OLD;
    END;
    $function$
