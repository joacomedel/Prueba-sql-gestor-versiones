CREATE OR REPLACE FUNCTION public.ampagosafiliado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccpagosafiliado(NEW);
        return NEW;
    END;
    $function$
