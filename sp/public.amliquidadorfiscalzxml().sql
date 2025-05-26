CREATE OR REPLACE FUNCTION public.amliquidadorfiscalzxml()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccliquidadorfiscalzxml(NEW);
        return NEW;
    END;
    $function$
