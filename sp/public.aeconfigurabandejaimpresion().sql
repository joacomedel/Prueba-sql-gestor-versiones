CREATE OR REPLACE FUNCTION public.aeconfigurabandejaimpresion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccconfigurabandejaimpresion(OLD);
        return OLD;
    END;
    $function$
