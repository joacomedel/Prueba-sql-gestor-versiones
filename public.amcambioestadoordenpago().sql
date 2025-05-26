CREATE OR REPLACE FUNCTION public.amcambioestadoordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccambioestadoordenpago(NEW);
        return NEW;
    END;
    $function$
