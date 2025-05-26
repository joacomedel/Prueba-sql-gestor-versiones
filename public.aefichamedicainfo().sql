CREATE OR REPLACE FUNCTION public.aefichamedicainfo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfichamedicainfo(OLD);
        return OLD;
    END;
    $function$
