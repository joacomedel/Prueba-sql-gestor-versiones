CREATE OR REPLACE FUNCTION public.amcambioestadosorden()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccambioestadosorden(NEW);
        return NEW;
    END;
    $function$
