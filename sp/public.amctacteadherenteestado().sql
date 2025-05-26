CREATE OR REPLACE FUNCTION public.amctacteadherenteestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccctacteadherenteestado(NEW);
        return NEW;
    END;
    $function$
