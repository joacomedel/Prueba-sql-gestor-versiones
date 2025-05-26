CREATE OR REPLACE FUNCTION public.eliminarccfechasfact(fila fechasfact)
 RETURNS fechasfact
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.fechasfactcc:= current_timestamp;
    delete from sincro.fechasfact WHERE fechafin= fila.fechafin AND idrecepcion= fila.idrecepcion AND fechainicio= fila.fechainicio AND TRUE;
    RETURN fila;
    END;
    $function$
