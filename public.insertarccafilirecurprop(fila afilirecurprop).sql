CREATE OR REPLACE FUNCTION public.insertarccafilirecurprop(fila afilirecurprop)
 RETURNS afilirecurprop
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.afilirecurpropcc:= current_timestamp;
    UPDATE sincro.afilirecurprop SET afilirecurpropcc= fila.afilirecurpropcc, legajosiu= fila.legajosiu, mutu= fila.mutu, nrodoc= fila.nrodoc, nromutu= fila.nromutu, tipodoc= fila.tipodoc WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.afilirecurprop(afilirecurpropcc, legajosiu, mutu, nrodoc, nromutu, tipodoc) VALUES (fila.afilirecurpropcc, fila.legajosiu, fila.mutu, fila.nrodoc, fila.nromutu, fila.tipodoc);
    END IF;
    RETURN fila;
    END;
    $function$
