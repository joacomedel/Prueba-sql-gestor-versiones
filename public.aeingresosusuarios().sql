CREATE OR REPLACE FUNCTION public.aeingresosusuarios()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccingresosusuarios(OLD);
        return OLD;
    END;
    $function$
