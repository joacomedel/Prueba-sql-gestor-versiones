CREATE OR REPLACE FUNCTION public.amacciofar()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccacciofar(NEW);
        return NEW;
    END;
    $function$
