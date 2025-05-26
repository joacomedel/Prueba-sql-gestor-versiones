CREATE OR REPLACE FUNCTION public.aecuentacorrientedeudapagocompensacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccuentacorrientedeudapagocompensacion(OLD);
        return OLD;
    END;
    $function$
