CREATE OR REPLACE FUNCTION public.amfechasfact()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfechasfact(NEW);
        return NEW;
    END;
    $function$
