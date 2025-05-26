CREATE OR REPLACE FUNCTION public.aecambioestadoordenpago()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarcccambioestadoordenpago(OLD);
        return OLD;
    END;
    $function$
