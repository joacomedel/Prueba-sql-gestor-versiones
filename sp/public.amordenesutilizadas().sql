CREATE OR REPLACE FUNCTION public.amordenesutilizadas()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenesutilizadas(NEW);
        return NEW;
    END;
    $function$
