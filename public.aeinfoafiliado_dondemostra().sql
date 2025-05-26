CREATE OR REPLACE FUNCTION public.aeinfoafiliado_dondemostra()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinfoafiliado_dondemostra(OLD);
        return OLD;
    END;
    $function$
