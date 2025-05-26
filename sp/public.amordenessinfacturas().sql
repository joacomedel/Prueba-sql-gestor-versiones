CREATE OR REPLACE FUNCTION public.amordenessinfacturas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenessinfacturas(NEW);
        return NEW;
    END;
    $function$
