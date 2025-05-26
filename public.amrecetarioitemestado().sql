CREATE OR REPLACE FUNCTION public.amrecetarioitemestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecetarioitemestado(NEW);
        return NEW;
    END;
    $function$
