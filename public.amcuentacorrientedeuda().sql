CREATE OR REPLACE FUNCTION public.amcuentacorrientedeuda()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccuentacorrientedeuda(NEW);
        return NEW;
    END;
    $function$
