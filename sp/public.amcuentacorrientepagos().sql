CREATE OR REPLACE FUNCTION public.amcuentacorrientepagos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccuentacorrientepagos(NEW);
        return NEW;
    END;
    $function$
