CREATE OR REPLACE FUNCTION public.insertarccadmitemusousuario(fila admitemusousuario)
 RETURNS admitemusousuario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.admitemusousuariocc:= current_timestamp;
    UPDATE sincro.admitemusousuario SET admitemusousuariocc= fila.admitemusousuariocc, aiuucantidad= fila.aiuucantidad, aiuufecha= fila.aiuufecha, direccionip= fila.direccionip, idadmitemusousuario= fila.idadmitemusousuario, idcentroregional= fila.idcentroregional, iditem= fila.iditem, idusuario= fila.idusuario WHERE idcentroregional= fila.idcentroregional AND idadmitemusousuario= fila.idadmitemusousuario AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.admitemusousuario(admitemusousuariocc, aiuucantidad, aiuufecha, direccionip, idadmitemusousuario, idcentroregional, iditem, idusuario) VALUES (fila.admitemusousuariocc, fila.aiuucantidad, fila.aiuufecha, fila.direccionip, fila.idadmitemusousuario, fila.idcentroregional, fila.iditem, fila.idusuario);
    END IF;
    RETURN fila;
    END;
    $function$
