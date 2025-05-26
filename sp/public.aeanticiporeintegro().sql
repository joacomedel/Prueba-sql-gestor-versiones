CREATE OR REPLACE FUNCTION public.aeanticiporeintegro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccanticiporeintegro(OLD);
        return OLD;
    END;
    $function$
