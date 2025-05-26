CREATE OR REPLACE FUNCTION public.eliminarcccliente(fila cliente)
 RETURNS cliente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.clientecc:= current_timestamp;
    delete from sincro.cliente WHERE barra= fila.barra AND nrocliente= fila.nrocliente AND TRUE;
    RETURN fila;
    END;
    $function$
