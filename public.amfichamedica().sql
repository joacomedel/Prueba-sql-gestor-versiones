CREATE OR REPLACE FUNCTION public.amfichamedica()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedica(NEW);
        return NEW;
    END;
    $function$
