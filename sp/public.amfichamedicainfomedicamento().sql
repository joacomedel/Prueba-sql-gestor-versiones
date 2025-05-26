CREATE OR REPLACE FUNCTION public.amfichamedicainfomedicamento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicainfomedicamento(NEW);
        return NEW;
    END;
    $function$
