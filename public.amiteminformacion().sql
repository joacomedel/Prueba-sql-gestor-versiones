CREATE OR REPLACE FUNCTION public.amiteminformacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcciteminformacion(NEW);
        return NEW;
    END;
    $function$
