CREATE OR REPLACE FUNCTION public.eliminarccbeneficiariosborrados(fila beneficiariosborrados)
 RETURNS beneficiariosborrados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.beneficiariosborradoscc:= current_timestamp;
    delete from sincro.beneficiariosborrados WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
