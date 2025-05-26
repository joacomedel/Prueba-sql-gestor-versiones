CREATE OR REPLACE FUNCTION public.eliminarccpersonajuridicabis(fila personajuridicabis)
 RETURNS personajuridicabis
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.personajuridicabiscc:= current_timestamp;
    delete from sincro.personajuridicabis WHERE barra= fila.barra AND nrocliente= fila.nrocliente AND TRUE;
    RETURN fila;
    END;
    $function$
