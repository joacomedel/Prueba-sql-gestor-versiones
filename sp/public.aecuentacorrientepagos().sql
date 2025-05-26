CREATE OR REPLACE FUNCTION public.aecuentacorrientepagos()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccuentacorrientepagos(OLD);
        return OLD;
    END;
    $function$
