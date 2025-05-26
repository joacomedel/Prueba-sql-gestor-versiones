CREATE OR REPLACE FUNCTION public.insertarccclientectacte(fila clientectacte)
 RETURNS clientectacte
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.clientectactecc:= current_timestamp;
    UPDATE sincro.clientectacte SET barra= fila.barra, cccborrado= fila.cccborrado, cccdtohaberes= fila.cccdtohaberes, cccidusuario= fila.cccidusuario, clientectactecc= fila.clientectactecc, idcentroclientectacte= fila.idcentroclientectacte, idclientectacte= fila.idclientectacte, nrocliente= fila.nrocliente WHERE idclientectacte= fila.idclientectacte AND idcentroclientectacte= fila.idcentroclientectacte AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.clientectacte(barra, cccborrado, cccdtohaberes, cccidusuario, clientectactecc, idcentroclientectacte, idclientectacte, nrocliente) VALUES (fila.barra, fila.cccborrado, fila.cccdtohaberes, fila.cccidusuario, fila.clientectactecc, fila.idcentroclientectacte, fila.idclientectacte, fila.nrocliente);
    END IF;
    RETURN fila;
    END;
    $function$
