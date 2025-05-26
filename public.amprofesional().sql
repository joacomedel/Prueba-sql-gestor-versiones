CREATE OR REPLACE FUNCTION public.amprofesional()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccprofesional(NEW);
        return NEW;
    END;
    $function$
