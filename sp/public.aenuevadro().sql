CREATE OR REPLACE FUNCTION public.aenuevadro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccnuevadro(OLD);
        return OLD;
    END;
    $function$
