CREATE OR REPLACE FUNCTION public.aefar_stockajusteiteminformado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfar_stockajusteiteminformado(OLD);
        return OLD;
    END;
    $function$
