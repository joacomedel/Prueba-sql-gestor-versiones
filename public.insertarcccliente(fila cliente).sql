CREATE OR REPLACE FUNCTION public.insertarcccliente(fila cliente)
 RETURNS cliente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.clientecc:= current_timestamp;
    UPDATE sincro.cliente SET barra= fila.barra, clientecc= fila.clientecc, cuitfin= fila.cuitfin, cuitini= fila.cuitini, cuitmedio= fila.cuitmedio, denominacion= fila.denominacion, email= fila.email, idcentrodireccion= fila.idcentrodireccion, idcondicioniva= fila.idcondicioniva, iddireccion= fila.iddireccion, idtipocliente= fila.idtipocliente, nrocliente= fila.nrocliente, telefono= fila.telefono WHERE barra= fila.barra AND nrocliente= fila.nrocliente AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.cliente(barra, clientecc, cuitfin, cuitini, cuitmedio, denominacion, email, idcentrodireccion, idcondicioniva, iddireccion, idtipocliente, nrocliente, telefono) VALUES (fila.barra, fila.clientecc, fila.cuitfin, fila.cuitini, fila.cuitmedio, fila.denominacion, fila.email, fila.idcentrodireccion, fila.idcondicioniva, fila.iddireccion, fila.idtipocliente, fila.nrocliente, fila.telefono);
    END IF;
    RETURN fila;
    END;
    $function$
