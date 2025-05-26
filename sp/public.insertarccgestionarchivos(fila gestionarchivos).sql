CREATE OR REPLACE FUNCTION public.insertarccgestionarchivos(fila gestionarchivos)
 RETURNS gestionarchivos
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.gestionarchivoscc:= current_timestamp;
    UPDATE sincro.gestionarchivos SET gaactivo= fila.gaactivo, gaarchivo= fila.gaarchivo, gaarchivodescripcion= fila.gaarchivodescripcion, gaarchivonombre= fila.gaarchivonombre, gafechacreacion= fila.gafechacreacion, gaidusuariocarga= fila.gaidusuariocarga, gestionarchivoscc= fila.gestionarchivoscc, idcentrogestionarchivos= fila.idcentrogestionarchivos, idgestionarchivos= fila.idgestionarchivos WHERE idgestionarchivos= fila.idgestionarchivos AND idcentrogestionarchivos= fila.idcentrogestionarchivos AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.gestionarchivos(gaactivo, gaarchivo, gaarchivodescripcion, gaarchivonombre, gafechacreacion, gaidusuariocarga, gestionarchivoscc, idcentrogestionarchivos, idgestionarchivos) VALUES (fila.gaactivo, fila.gaarchivo, fila.gaarchivodescripcion, fila.gaarchivonombre, fila.gafechacreacion, fila.gaidusuariocarga, fila.gestionarchivoscc, fila.idcentrogestionarchivos, fila.idgestionarchivos);
    END IF;
    RETURN fila;
    END;
    $function$
