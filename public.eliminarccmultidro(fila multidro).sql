CREATE OR REPLACE FUNCTION public.eliminarccmultidro(fila multidro)
 RETURNS multidro
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.multidrocc:= current_timestamp;
    delete from sincro.multidro WHERE idnuevadro= fila.idnuevadro AND mnroregistro= fila.mnroregistro AND nomenclado= fila.nomenclado AND TRUE;
    RETURN fila;
    END;
    $function$
