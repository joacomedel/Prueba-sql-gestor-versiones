CREATE OR REPLACE FUNCTION public.amconfigurabandejaimpresion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccconfigurabandejaimpresion(NEW);
        return NEW;
    END;
    $function$
