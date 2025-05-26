CREATE OR REPLACE FUNCTION public.eliminarccinfaportesfaltantes(fila infaportesfaltantes)
 RETURNS infaportesfaltantes
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.infaportesfaltantescc:= current_timestamp;
    delete from sincro.infaportesfaltantes WHERE anio= fila.anio AND barra= fila.barra AND fechamodificacion= fila.fechamodificacion AND mes= fila.mes AND nrodoc= fila.nrodoc AND nrotipoinforme= fila.nrotipoinforme AND tipodoc= fila.tipodoc AND tipoinforme= fila.tipoinforme AND TRUE;
    RETURN fila;
    END;
    $function$
