CREATE OR REPLACE FUNCTION public.amusuariopersona()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccusuariopersona(NEW);
        return NEW;
    END;
    $function$
