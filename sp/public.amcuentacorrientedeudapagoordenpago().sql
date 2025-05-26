CREATE OR REPLACE FUNCTION public.amcuentacorrientedeudapagoordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccuentacorrientedeudapagoordenpago(NEW);
        return NEW;
    END;
    $function$
