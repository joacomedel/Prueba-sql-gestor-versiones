CREATE OR REPLACE FUNCTION public.amnuevadro()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccnuevadro(NEW);
        return NEW;
    END;
    $function$
