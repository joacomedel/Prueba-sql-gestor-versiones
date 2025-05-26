CREATE OR REPLACE FUNCTION public.amreciboautomatico()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccreciboautomatico(NEW);
        return NEW;
    END;
    $function$
