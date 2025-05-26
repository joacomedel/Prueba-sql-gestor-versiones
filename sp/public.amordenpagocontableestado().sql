CREATE OR REPLACE FUNCTION public.amordenpagocontableestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenpagocontableestado(NEW);
        return NEW;
    END;
    $function$
