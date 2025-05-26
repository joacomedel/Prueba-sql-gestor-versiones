CREATE OR REPLACE FUNCTION public.eliminarccpersonajuridica(fila personajuridica)
 RETURNS personajuridica
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.personajuridicacc:= current_timestamp;
    delete from sincro.personajuridica WHERE idprestador= fila.idprestador AND TRUE;
    RETURN fila;
    END;
    $function$
