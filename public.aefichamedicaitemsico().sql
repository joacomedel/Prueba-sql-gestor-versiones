CREATE OR REPLACE FUNCTION public.aefichamedicaitemsico()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicaitemsico(OLD);
        return OLD;
    END;
    $function$
