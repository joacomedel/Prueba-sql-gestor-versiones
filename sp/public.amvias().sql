CREATE OR REPLACE FUNCTION public.amvias()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccvias(NEW);
        return NEW;
    END;
    $function$
