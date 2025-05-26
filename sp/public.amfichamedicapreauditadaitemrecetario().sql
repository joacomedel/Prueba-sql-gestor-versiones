CREATE OR REPLACE FUNCTION public.amfichamedicapreauditadaitemrecetario()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicapreauditadaitemrecetario(NEW);
        return NEW;
    END;
    $function$
