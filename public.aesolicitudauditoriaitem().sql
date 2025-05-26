CREATE OR REPLACE FUNCTION public.aesolicitudauditoriaitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccsolicitudauditoriaitem(OLD);
        return OLD;
    END;
    $function$
