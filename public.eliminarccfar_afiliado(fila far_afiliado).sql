CREATE OR REPLACE FUNCTION public.eliminarccfar_afiliado(fila far_afiliado)
 RETURNS far_afiliado
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_afiliadocc:= current_timestamp;
    delete from sincro.far_afiliado WHERE tipodoc= fila.tipodoc AND nrodoc= fila.nrodoc AND idobrasocial= fila.idobrasocial AND TRUE;
    RETURN fila;
    END;
    $function$
