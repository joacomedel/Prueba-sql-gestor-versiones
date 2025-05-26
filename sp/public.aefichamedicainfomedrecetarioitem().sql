CREATE OR REPLACE FUNCTION public.aefichamedicainfomedrecetarioitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicainfomedrecetarioitem(OLD);
        return OLD;
    END;
    $function$
