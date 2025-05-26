CREATE OR REPLACE FUNCTION public.aefarmtipounid()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    OLD:= eliminarccfarmtipounid(OLD);
        return OLD;
    END;
    $function$
