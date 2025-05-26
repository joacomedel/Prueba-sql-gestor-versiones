CREATE OR REPLACE FUNCTION public.amtafiliado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcctafiliado(NEW);
        return NEW;
    END;
    $function$
