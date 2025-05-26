CREATE OR REPLACE FUNCTION public.amordenestados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenestados(NEW);
        return NEW;
    END;
    $function$
