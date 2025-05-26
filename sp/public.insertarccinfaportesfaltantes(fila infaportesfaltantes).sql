CREATE OR REPLACE FUNCTION public.insertarccinfaportesfaltantes(fila infaportesfaltantes)
 RETURNS infaportesfaltantes
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.infaportesfaltantescc:= current_timestamp;
    UPDATE sincro.infaportesfaltantes SET anio= fila.anio, barra= fila.barra, fechamodificacion= fila.fechamodificacion, fechareclamo= fila.fechareclamo, infaportesfaltantescc= fila.infaportesfaltantescc, mes= fila.mes, nrodoc= fila.nrodoc, nrotipoinforme= fila.nrotipoinforme, tipodoc= fila.tipodoc, tipoinforme= fila.tipoinforme WHERE anio= fila.anio AND barra= fila.barra AND fechamodificacion= fila.fechamodificacion AND mes= fila.mes AND nrodoc= fila.nrodoc AND nrotipoinforme= fila.nrotipoinforme AND tipodoc= fila.tipodoc AND tipoinforme= fila.tipoinforme AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.infaportesfaltantes(anio, barra, fechamodificacion, fechareclamo, infaportesfaltantescc, mes, nrodoc, nrotipoinforme, tipodoc, tipoinforme) VALUES (fila.anio, fila.barra, fila.fechamodificacion, fila.fechareclamo, fila.infaportesfaltantescc, fila.mes, fila.nrodoc, fila.nrotipoinforme, fila.tipodoc, fila.tipoinforme);
    END IF;
    RETURN fila;
    END;
    $function$
