CREATE OR REPLACE FUNCTION public.aemapeoprestadores()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccmapeoprestadores(OLD);
        return OLD;
    END;
    $function$
