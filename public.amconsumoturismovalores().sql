CREATE OR REPLACE FUNCTION public.amconsumoturismovalores()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccconsumoturismovalores(NEW);
        return NEW;
    END;
    $function$
