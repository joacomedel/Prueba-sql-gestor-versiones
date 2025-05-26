CREATE OR REPLACE FUNCTION public.amctactepagocliente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccctactepagocliente(NEW);
        return NEW;
    END;
    $function$
