CREATE OR REPLACE FUNCTION public.insertarccadmusuarios(fila admusuarios)
 RETURNS admusuarios
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.admusuarioscc:= current_timestamp;
    UPDATE sincro.admusuarios SET admusuarioscc= fila.admusuarioscc, apellido= fila.apellido, contrasena= fila.contrasena, login= fila.login, nombre= fila.nombre, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.admusuarios(admusuarioscc, apellido, contrasena, login, nombre, nrodoc, tipodoc) VALUES (fila.admusuarioscc, fila.apellido, fila.contrasena, fila.login, fila.nombre, fila.nrodoc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
