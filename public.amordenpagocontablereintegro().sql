CREATE OR REPLACE FUNCTION public.amordenpagocontablereintegro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenpagocontablereintegro(NEW);
        return NEW;
    END;
    $function$
