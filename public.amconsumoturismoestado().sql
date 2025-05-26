CREATE OR REPLACE FUNCTION public.amconsumoturismoestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccconsumoturismoestado(NEW);
        return NEW;
    END;
    $function$
