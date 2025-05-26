CREATE OR REPLACE FUNCTION public.eliminarccadmitemusousuario(fila admitemusousuario)
 RETURNS admitemusousuario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.admitemusousuariocc:= current_timestamp;
    delete from sincro.admitemusousuario WHERE idcentroregional= fila.idcentroregional AND idadmitemusousuario= fila.idadmitemusousuario AND TRUE;
    RETURN fila;
    END;
    $function$
