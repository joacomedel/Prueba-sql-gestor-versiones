CREATE OR REPLACE FUNCTION public.aepresupuestoitemordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccpresupuestoitemordenpago(OLD);
        return OLD;
    END;
    $function$
