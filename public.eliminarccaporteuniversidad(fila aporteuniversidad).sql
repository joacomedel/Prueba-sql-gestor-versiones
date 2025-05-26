CREATE OR REPLACE FUNCTION public.eliminarccaporteuniversidad(fila aporteuniversidad)
 RETURNS aporteuniversidad
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.aporteuniversidadcc:= current_timestamp;
    delete from sincro.aporteuniversidad WHERE anio= fila.anio AND mes= fila.mes AND nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
