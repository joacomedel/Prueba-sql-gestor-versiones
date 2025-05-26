CREATE OR REPLACE FUNCTION public.insertarccfar_afiliado(fila far_afiliado)
 RETURNS far_afiliado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_afiliadocc:= current_timestamp;
    UPDATE sincro.far_afiliado SET nrodoc= fila.nrodoc, far_afiliadocc= fila.far_afiliadocc, idcentrodireccion= fila.idcentrodireccion, nrocliente= fila.nrocliente, idobrasocial= fila.idobrasocial, aapellidoynombre= fila.aapellidoynombre, idafiliado= fila.idafiliado, barra= fila.barra, idcentroafiliado= fila.idcentroafiliado, tipodoc= fila.tipodoc, iddireccion= fila.iddireccion, aidafiliadoobrasocial= fila.aidafiliadoobrasocial WHERE tipodoc= fila.tipodoc AND nrodoc= fila.nrodoc AND idobrasocial= fila.idobrasocial AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.far_afiliado(nrodoc, far_afiliadocc, idcentrodireccion, nrocliente, idobrasocial, aapellidoynombre, idafiliado, barra, idcentroafiliado, tipodoc, iddireccion, aidafiliadoobrasocial) VALUES (fila.nrodoc, fila.far_afiliadocc, fila.idcentrodireccion, fila.nrocliente, fila.idobrasocial, fila.aapellidoynombre, fila.idafiliado, fila.barra, fila.idcentroafiliado, fila.tipodoc, fila.iddireccion, fila.aidafiliadoobrasocial);
    END IF;
    RETURN fila;
    END;
    $function$
