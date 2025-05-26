CREATE OR REPLACE FUNCTION public.aectacteadherenteestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccctacteadherenteestado(OLD);
        return OLD;
    END;
    $function$
