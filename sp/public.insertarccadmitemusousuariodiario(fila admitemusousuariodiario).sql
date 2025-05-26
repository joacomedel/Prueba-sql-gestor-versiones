CREATE OR REPLACE FUNCTION public.insertarccadmitemusousuariodiario(fila admitemusousuariodiario)
 RETURNS admitemusousuariodiario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.admitemusousuariodiariocc:= current_timestamp;
    UPDATE sincro.admitemusousuariodiario SET admitemusousuariodiariocc= fila.admitemusousuariodiariocc, aiuudcantidad= fila.aiuudcantidad, aiuudfecha= fila.aiuudfecha, idadmitemusousuariodiario= fila.idadmitemusousuariodiario, idcentroadmitemusousuariodiario= fila.idcentroadmitemusousuariodiario, iditem= fila.iditem, idusuario= fila.idusuario WHERE idcentroadmitemusousuariodiario= fila.idcentroadmitemusousuariodiario AND idadmitemusousuariodiario= fila.idadmitemusousuariodiario AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.admitemusousuariodiario(admitemusousuariodiariocc, aiuudcantidad, aiuudfecha, idadmitemusousuariodiario, idcentroadmitemusousuariodiario, iditem, idusuario) VALUES (fila.admitemusousuariodiariocc, fila.aiuudcantidad, fila.aiuudfecha, fila.idadmitemusousuariodiario, fila.idcentroadmitemusousuariodiario, fila.iditem, fila.idusuario);
    END IF;
    RETURN fila;
    END;
    $function$
