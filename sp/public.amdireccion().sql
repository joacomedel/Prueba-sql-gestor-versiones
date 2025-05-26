CREATE OR REPLACE FUNCTION public.amdireccion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccdireccion(NEW);
        return NEW;
    END;
    $function$
