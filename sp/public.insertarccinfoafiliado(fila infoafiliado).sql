CREATE OR REPLACE FUNCTION public.insertarccinfoafiliado(fila infoafiliado)
 RETURNS infoafiliado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.infoafiliadocc:= current_timestamp;
    UPDATE sincro.infoafiliado SET iafechafin= fila.iafechafin, iafechaini= fila.iafechaini, iagrupofamiliar= fila.iagrupofamiliar, iaidusuario= fila.iaidusuario, iatexto= fila.iatexto, idcentroinfoafiliado= fila.idcentroinfoafiliado, idinfoafiliado= fila.idinfoafiliado, infoafiliadocc= fila.infoafiliadocc, nrodoc= fila.nrodoc, tipodoc= fila.tipodoc WHERE idinfoafiliado= fila.idinfoafiliado AND idcentroinfoafiliado= fila.idcentroinfoafiliado AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.infoafiliado(iafechafin, iafechaini, iagrupofamiliar, iaidusuario, iatexto, idcentroinfoafiliado, idinfoafiliado, infoafiliadocc, nrodoc, tipodoc) VALUES (fila.iafechafin, fila.iafechaini, fila.iagrupofamiliar, fila.iaidusuario, fila.iatexto, fila.idcentroinfoafiliado, fila.idinfoafiliado, fila.infoafiliadocc, fila.nrodoc, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
