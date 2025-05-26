CREATE OR REPLACE FUNCTION public.amfichamedicapreauditada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicapreauditada(NEW);
        return NEW;
    END;
    $function$
