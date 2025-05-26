CREATE OR REPLACE FUNCTION public.eliminarccadmitemusousuariodiario(fila admitemusousuariodiario)
 RETURNS admitemusousuariodiario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.admitemusousuariodiariocc:= current_timestamp;
    delete from sincro.admitemusousuariodiario WHERE idcentroadmitemusousuariodiario= fila.idcentroadmitemusousuariodiario AND idadmitemusousuariodiario= fila.idadmitemusousuariodiario AND TRUE;
    RETURN fila;
    END;
    $function$
