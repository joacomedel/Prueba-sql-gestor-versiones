CREATE OR REPLACE FUNCTION public.amfichamedicapreauditadaitemconsulta()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicapreauditadaitemconsulta(NEW);
        return NEW;
    END;
    $function$
