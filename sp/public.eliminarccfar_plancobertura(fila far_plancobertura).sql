CREATE OR REPLACE FUNCTION public.eliminarccfar_plancobertura(fila far_plancobertura)
 RETURNS far_plancobertura
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_plancoberturacc:= current_timestamp;
    delete from sincro.far_plancobertura WHERE idplancobertura= fila.idplancobertura AND TRUE;
    RETURN fila;
    END;
    $function$
