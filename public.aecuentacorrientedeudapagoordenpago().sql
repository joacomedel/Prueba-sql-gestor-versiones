CREATE OR REPLACE FUNCTION public.aecuentacorrientedeudapagoordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccuentacorrientedeudapagoordenpago(OLD);
        return OLD;
    END;
    $function$
