CREATE OR REPLACE FUNCTION public.eliminarccpersona_token(fila persona_token)
 RETURNS persona_token
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.persona_tokencc:= current_timestamp;
    delete from sincro.persona_token WHERE idpersonatoken= fila.idpersonatoken AND idcentropersonatoken= fila.idcentropersonatoken AND TRUE;
    RETURN fila;
    END;
    $function$
