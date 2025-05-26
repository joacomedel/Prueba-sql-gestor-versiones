CREATE OR REPLACE FUNCTION public.amfar_stockajusteiteminformado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_stockajusteiteminformado(NEW);
        return NEW;
    END;
    $function$
