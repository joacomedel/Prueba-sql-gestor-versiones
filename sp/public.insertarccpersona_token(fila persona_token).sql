CREATE OR REPLACE FUNCTION public.insertarccpersona_token(fila persona_token)
 RETURNS persona_token
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.persona_tokencc:= current_timestamp;
    UPDATE sincro.persona_token SET idcentropersonatoken= fila.idcentropersonatoken, idpersonatoken= fila.idpersonatoken, nrodoc= fila.nrodoc, persona_tokencc= fila.persona_tokencc, ptfechaemision= fila.ptfechaemision, ptfechavencimiento= fila.ptfechavencimiento, ptinfoutilizado= fila.ptinfoutilizado, pttoken= fila.pttoken, ptutilizado= fila.ptutilizado, tipodoc= fila.tipodoc WHERE idpersonatoken= fila.idpersonatoken AND idcentropersonatoken= fila.idcentropersonatoken AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.persona_token(idcentropersonatoken, idpersonatoken, nrodoc, persona_tokencc, ptfechaemision, ptfechavencimiento, ptinfoutilizado, pttoken, ptutilizado, tipodoc) VALUES (fila.idcentropersonatoken, fila.idpersonatoken, fila.nrodoc, fila.persona_tokencc, fila.ptfechaemision, fila.ptfechavencimiento, fila.ptinfoutilizado, fila.pttoken, fila.ptutilizado, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
