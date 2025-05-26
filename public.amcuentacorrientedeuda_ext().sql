CREATE OR REPLACE FUNCTION public.amcuentacorrientedeuda_ext()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccuentacorrientedeuda_ext(NEW);
        return NEW;
    END;
    $function$
