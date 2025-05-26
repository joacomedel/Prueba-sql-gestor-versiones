CREATE OR REPLACE FUNCTION public.amdocumento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccdocumento(NEW);
        return NEW;
    END;
    $function$
