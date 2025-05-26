CREATE OR REPLACE FUNCTION public.aedocumento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccdocumento(OLD);
        return OLD;
    END;
    $function$
