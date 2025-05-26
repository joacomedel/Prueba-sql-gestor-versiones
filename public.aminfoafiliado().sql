CREATE OR REPLACE FUNCTION public.aminfoafiliado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinfoafiliado(NEW);
        return NEW;
    END;
    $function$
