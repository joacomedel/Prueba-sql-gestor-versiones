CREATE OR REPLACE FUNCTION public.insertarccrecibo(fila recibo)
 RETURNS recibo
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.recibocc:= current_timestamp;
    UPDATE sincro.recibo SET centro= fila.centro, fecharecibo= fila.fecharecibo, idrecibo= fila.idrecibo, idusuarioreanulado= fila.idusuarioreanulado, importeenletras= fila.importeenletras, importerecibo= fila.importerecibo, imputacionrecibo= fila.imputacionrecibo, nroimpreso= fila.nroimpreso, reanulado= fila.reanulado, rebarra= fila.rebarra, recibocc= fila.recibocc, renrocliente= fila.renrocliente WHERE idrecibo= fila.idrecibo AND centro= fila.centro AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.recibo(centro, fecharecibo, idrecibo, idusuarioreanulado, importeenletras, importerecibo, imputacionrecibo, nroimpreso, reanulado, rebarra, recibocc, renrocliente) VALUES (fila.centro, fila.fecharecibo, fila.idrecibo, fila.idusuarioreanulado, fila.importeenletras, fila.importerecibo, fila.imputacionrecibo, fila.nroimpreso, fila.reanulado, fila.rebarra, fila.recibocc, fila.renrocliente);
    END IF;
    RETURN fila;
    END;
    $function$
