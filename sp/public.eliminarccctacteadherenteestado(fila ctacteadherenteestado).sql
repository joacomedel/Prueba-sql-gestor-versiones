CREATE OR REPLACE FUNCTION public.eliminarccctacteadherenteestado(fila ctacteadherenteestado)
 RETURNS ctacteadherenteestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.ctacteadherenteestadocc:= current_timestamp;
    delete from sincro.ctacteadherenteestado WHERE idctacteadherenteestado= fila.idctacteadherenteestado AND idcentroctacteadherenteestado= fila.idcentroctacteadherenteestado AND TRUE;
    RETURN fila;
    END;
    $function$
