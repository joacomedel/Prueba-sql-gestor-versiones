CREATE OR REPLACE FUNCTION public.insertarccsubsidios(fila subsidios)
 RETURNS subsidios
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.subsidioscc:= current_timestamp;
    UPDATE sincro.subsidios SET apellido= fila.apellido, clave= fila.clave, existe= fila.existe, idcentroregional= fila.idcentroregional, nombres= fila.nombres, nro= fila.nro, nrodoc= fila.nrodoc, nrodoctitu= fila.nrodoctitu, porcent= fila.porcent, subsidioscc= fila.subsidioscc, tipodoc= fila.tipodoc, tipodoctitu= fila.tipodoctitu, vinculo= fila.vinculo WHERE clave= fila.clave AND idcentroregional= fila.idcentroregional AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.subsidios(apellido, clave, existe, idcentroregional, nombres, nro, nrodoc, nrodoctitu, porcent, subsidioscc, tipodoc, tipodoctitu, vinculo) VALUES (fila.apellido, fila.clave, fila.existe, fila.idcentroregional, fila.nombres, fila.nro, fila.nrodoc, fila.nrodoctitu, fila.porcent, fila.subsidioscc, fila.tipodoc, fila.tipodoctitu, fila.vinculo);
    END IF;
    RETURN fila;
    END;
    $function$
