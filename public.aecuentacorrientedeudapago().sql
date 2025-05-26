CREATE OR REPLACE FUNCTION public.aecuentacorrientedeudapago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccuentacorrientedeudapago(OLD);
        return OLD;
    END;
    $function$
