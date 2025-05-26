CREATE OR REPLACE FUNCTION public.aedocumentoitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccdocumentoitem(OLD);
        return OLD;
    END;
    $function$
