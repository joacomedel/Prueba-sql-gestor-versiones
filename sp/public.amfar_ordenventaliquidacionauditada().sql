CREATE OR REPLACE FUNCTION public.amfar_ordenventaliquidacionauditada()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_ordenventaliquidacionauditada(NEW);
        return NEW;
    END;
    $function$
