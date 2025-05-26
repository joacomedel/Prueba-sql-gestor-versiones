CREATE OR REPLACE FUNCTION public.eliminarccfar_vendedor(fila far_vendedor)
 RETURNS far_vendedor
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.far_vendedorcc:= current_timestamp;
    delete from sincro.far_vendedor WHERE idvendedor= fila.idvendedor AND TRUE;
    RETURN fila;
    END;
    $function$
