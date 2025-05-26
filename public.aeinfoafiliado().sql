CREATE OR REPLACE FUNCTION public.aeinfoafiliado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccinfoafiliado(OLD);
        return OLD;
    END;
    $function$
