CREATE OR REPLACE FUNCTION public.aeordenrecibo_vinculada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccordenrecibo_vinculada(OLD);
        return OLD;
    END;
    $function$
