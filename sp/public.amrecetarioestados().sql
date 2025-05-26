CREATE OR REPLACE FUNCTION public.amrecetarioestados()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecetarioestados(NEW);
        return NEW;
    END;
    $function$
