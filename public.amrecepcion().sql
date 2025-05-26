CREATE OR REPLACE FUNCTION public.amrecepcion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccrecepcion(NEW);
        return NEW;
    END;
    $function$
