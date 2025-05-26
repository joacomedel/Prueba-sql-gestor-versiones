CREATE OR REPLACE FUNCTION public.amordenrecibo_vinculada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccordenrecibo_vinculada(NEW);
        return NEW;
    END;
    $function$
