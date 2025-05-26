CREATE OR REPLACE FUNCTION public.eliminarccfichamedicainfomedicamento(fila fichamedicainfomedicamento)
 RETURNS fichamedicainfomedicamento
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fichamedicainfomedicamentocc:= current_timestamp;
    delete from sincro.fichamedicainfomedicamento WHERE idfichamedicainfomedicamento= fila.idfichamedicainfomedicamento AND idcentrofichamedicainfomedicamento= fila.idcentrofichamedicainfomedicamento AND TRUE;
    RETURN fila;
    END;
    $function$
