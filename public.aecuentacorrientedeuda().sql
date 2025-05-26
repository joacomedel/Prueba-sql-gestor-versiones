CREATE OR REPLACE FUNCTION public.aecuentacorrientedeuda()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccuentacorrientedeuda(OLD);
        return OLD;
    END;
    $function$
