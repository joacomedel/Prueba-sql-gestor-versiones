CREATE OR REPLACE FUNCTION public.amfarmtipounid()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfarmtipounid(NEW);
        return NEW;
    END;
    $function$
