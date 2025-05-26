CREATE OR REPLACE FUNCTION public.amfestados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfestados(NEW);
        return NEW;
    END;
    $function$
