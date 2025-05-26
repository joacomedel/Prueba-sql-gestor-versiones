CREATE OR REPLACE FUNCTION public.amctasctesmontosdescuento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccctasctesmontosdescuento(NEW);
        return NEW;
    END;
    $function$
