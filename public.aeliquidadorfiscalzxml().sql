CREATE OR REPLACE FUNCTION public.aeliquidadorfiscalzxml()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccliquidadorfiscalzxml(OLD);
        return OLD;
    END;
    $function$
