CREATE OR REPLACE FUNCTION public.amcompramedicamento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarcccompramedicamento(NEW);
        return NEW;
    END;
    $function$
