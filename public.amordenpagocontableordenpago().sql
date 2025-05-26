CREATE OR REPLACE FUNCTION public.amordenpagocontableordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenpagocontableordenpago(NEW);
        return NEW;
    END;
    $function$
