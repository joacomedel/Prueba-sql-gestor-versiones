CREATE OR REPLACE FUNCTION public.insertarccdeclarasubs(fila declarasubs)
 RETURNS declarasubs
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.declarasubscc:= current_timestamp;
    UPDATE sincro.declarasubs SET apellido= fila.apellido, declarasubscc= fila.declarasubscc, nombres= fila.nombres, nro= fila.nro, nrodoc= fila.nrodoc, nrodoctitu= fila.nrodoctitu, porcent= fila.porcent, tipodoc= fila.tipodoc, tipodoctitu= fila.tipodoctitu, vinculo= fila.vinculo WHERE nro= fila.nro AND nrodoctitu= fila.nrodoctitu AND tipodoctitu= fila.tipodoctitu AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.declarasubs(apellido, declarasubscc, nombres, nro, nrodoc, nrodoctitu, porcent, tipodoc, tipodoctitu, vinculo) VALUES (fila.apellido, fila.declarasubscc, fila.nombres, fila.nro, fila.nrodoc, fila.nrodoctitu, fila.porcent, fila.tipodoc, fila.tipodoctitu, fila.vinculo);
    END IF;
    RETURN fila;
    END;
    $function$
