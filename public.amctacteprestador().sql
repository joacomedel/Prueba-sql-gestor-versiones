CREATE OR REPLACE FUNCTION public.amctacteprestador()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccctacteprestador(NEW);
        return NEW;
    END;
    $function$
