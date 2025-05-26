CREATE OR REPLACE FUNCTION public.insertarccusuario(fila usuario)
 RETURNS usuario
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.usuariocc:= current_timestamp;
    UPDATE sincro.usuario SET apellido= fila.apellido, contrasena= fila.contrasena, dni= fila.dni, idcentroregional= fila.idcentroregional, idusuario= fila.idusuario, login= fila.login, nombre= fila.nombre, tipodoc= fila.tipodoc, umail= fila.umail, usamenudinamico= fila.usamenudinamico, usuariocc= fila.usuariocc, usumultibd= fila.usumultibd, ususistemas= fila.ususistemas WHERE dni= fila.dni AND idcentroregional= fila.idcentroregional AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.usuario(apellido, contrasena, dni, idcentroregional, idusuario, login, nombre, tipodoc, umail, usamenudinamico, usuariocc, usumultibd, ususistemas) VALUES (fila.apellido, fila.contrasena, fila.dni, fila.idcentroregional, fila.idusuario, fila.login, fila.nombre, fila.tipodoc, fila.umail, fila.usamenudinamico, fila.usuariocc, fila.usumultibd, fila.ususistemas);
    END IF;
    RETURN fila;
    END;
    $function$
