CREATE OR REPLACE FUNCTION public.amaporteuniversidad()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccaporteuniversidad(NEW);
        return NEW;
    END;
    $function$
