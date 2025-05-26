CREATE OR REPLACE FUNCTION public.aemedicamento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccmedicamento(OLD);
        return OLD;
    END;
    $function$
