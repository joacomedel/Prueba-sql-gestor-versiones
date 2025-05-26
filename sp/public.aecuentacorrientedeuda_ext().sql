CREATE OR REPLACE FUNCTION public.aecuentacorrientedeuda_ext()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccuentacorrientedeuda_ext(OLD);
        return OLD;
    END;
    $function$
