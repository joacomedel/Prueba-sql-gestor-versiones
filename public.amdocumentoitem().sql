CREATE OR REPLACE FUNCTION public.amdocumentoitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccdocumentoitem(NEW);
        return NEW;
    END;
    $function$
