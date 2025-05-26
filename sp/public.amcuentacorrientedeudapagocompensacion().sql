CREATE OR REPLACE FUNCTION public.amcuentacorrientedeudapagocompensacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccuentacorrientedeudapagocompensacion(NEW);
        return NEW;
    END;
    $function$
