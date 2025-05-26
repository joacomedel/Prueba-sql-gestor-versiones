CREATE OR REPLACE FUNCTION public.amfichamedicaitemodonto()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicaitemodonto(NEW);
        return NEW;
    END;
    $function$
