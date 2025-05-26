CREATE OR REPLACE FUNCTION public.aeanticipoprestacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccanticipoprestacion(OLD);
        return OLD;
    END;
    $function$
