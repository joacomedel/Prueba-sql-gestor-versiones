CREATE OR REPLACE FUNCTION public.amfichamedicainfo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfichamedicainfo(NEW);
        return NEW;
    END;
    $function$
