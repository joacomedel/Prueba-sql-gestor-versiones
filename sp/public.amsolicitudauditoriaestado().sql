CREATE OR REPLACE FUNCTION public.amsolicitudauditoriaestado()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccsolicitudauditoriaestado(NEW);
        return NEW;
    END;
    $function$
