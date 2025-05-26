CREATE OR REPLACE FUNCTION public.amfichamedicaemisionestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicaemisionestado(NEW);
        return NEW;
    END;
    $function$
