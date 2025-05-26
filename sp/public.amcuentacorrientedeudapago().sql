CREATE OR REPLACE FUNCTION public.amcuentacorrientedeudapago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccuentacorrientedeudapago(NEW);
        return NEW;
    END;
    $function$
