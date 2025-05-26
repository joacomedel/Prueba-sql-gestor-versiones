CREATE OR REPLACE FUNCTION public.amsolicitudauditoriaitem()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
    NEW:= insertarccsolicitudauditoriaitem(NEW);
        return NEW;
    END;
    $function$
