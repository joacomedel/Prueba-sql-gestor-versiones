CREATE OR REPLACE FUNCTION public.amsubsidios()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccsubsidios(NEW);
        return NEW;
    END;
    $function$
