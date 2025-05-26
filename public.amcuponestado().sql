CREATE OR REPLACE FUNCTION public.amcuponestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccuponestado(NEW);
        return NEW;
    END;
    $function$
