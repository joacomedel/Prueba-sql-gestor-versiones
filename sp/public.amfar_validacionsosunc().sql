CREATE OR REPLACE FUNCTION public.amfar_validacionsosunc()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_validacionsosunc(NEW);
        return NEW;
    END;
    $function$
