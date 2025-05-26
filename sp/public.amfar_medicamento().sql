CREATE OR REPLACE FUNCTION public.amfar_medicamento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccfar_medicamento(NEW);
        return NEW;
    END;
    $function$
