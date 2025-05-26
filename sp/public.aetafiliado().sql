CREATE OR REPLACE FUNCTION public.aetafiliado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcctafiliado(OLD);
        return OLD;
    END;
    $function$
