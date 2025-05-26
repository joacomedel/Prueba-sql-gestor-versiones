CREATE OR REPLACE FUNCTION public.eliminarccfar_ordenventaitemimportesestado(fila far_ordenventaitemimportesestado)
 RETURNS far_ordenventaitemimportesestado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_ordenventaitemimportesestadocc:= current_timestamp;
    delete from sincro.far_ordenventaitemimportesestado WHERE idcentroordenventaitemimportesestado= fila.idcentroordenventaitemimportesestado AND idordenventaitemimportesaestado= fila.idordenventaitemimportesaestado AND TRUE;
    RETURN fila;
    END;
    $function$
