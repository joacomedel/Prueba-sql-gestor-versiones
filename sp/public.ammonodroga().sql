CREATE OR REPLACE FUNCTION public.ammonodroga()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccmonodroga(NEW);
        return NEW;
    END;
    $function$
