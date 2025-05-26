CREATE OR REPLACE FUNCTION public.amtipocliente()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcctipocliente(NEW);
        return NEW;
    END;
    $function$
