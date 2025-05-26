CREATE OR REPLACE FUNCTION public.eliminarccbeneficiariosreciborrados(fila beneficiariosreciborrados)
 RETURNS beneficiariosreciborrados
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.beneficiariosreciborradoscc:= current_timestamp;
    delete from sincro.beneficiariosreciborrados WHERE nrodoc= fila.nrodoc AND tipodoc= fila.tipodoc AND TRUE;
    RETURN fila;
    END;
    $function$
