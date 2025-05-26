CREATE OR REPLACE FUNCTION public.aminfoafiliado_dondemostra()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccinfoafiliado_dondemostra(NEW);
        return NEW;
    END;
    $function$
