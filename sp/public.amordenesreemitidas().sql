CREATE OR REPLACE FUNCTION public.amordenesreemitidas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenesreemitidas(NEW);
        return NEW;
    END;
    $function$
