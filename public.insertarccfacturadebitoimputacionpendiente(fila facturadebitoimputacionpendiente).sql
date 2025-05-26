CREATE OR REPLACE FUNCTION public.insertarccfacturadebitoimputacionpendiente(fila facturadebitoimputacionpendiente)
 RETURNS facturadebitoimputacionpendiente
 LANGUAGE plpgsql
AS $function$
    BEGIN
    fila.facturadebitoimputacionpendientecc:= current_timestamp;
    UPDATE sincro.facturadebitoimputacionpendiente SET motivo= fila.motivo, facturadebitoimputacionpendientecc= fila.facturadebitoimputacionpendientecc, anio= fila.anio, idrecibo= fila.idrecibo, nrocuentacgasto= fila.nrocuentacgasto, idcentrofacturadebitoimputacionpendiente= fila.idcentrofacturadebitoimputacionpendiente, centro= fila.centro, idplancobertura= fila.idplancobertura, idsubcapitulo= fila.idsubcapitulo, idfacturadebitoimputacionpendie= fila.idfacturadebitoimputacionpendie, nroregistro= fila.nroregistro, fidtipo= fila.fidtipo, idcapitulo= fila.idcapitulo, idmotivodebitofacturacion= fila.idmotivodebitofacturacion, importedebito= fila.importedebito, idpractica= fila.idpractica, idnomenclador= fila.idnomenclador, nroorden= fila.nroorden, idprestador= fila.idprestador, fdfecha= fila.fdfecha WHERE idfacturadebitoimputacionpendie= fila.idfacturadebitoimputacionpendie AND idcentrofacturadebitoimputacionpendiente= fila.idcentrofacturadebitoimputacionpendiente AND TRUE;
    IF NOT FOUND THEN
		INSERT INTO sincro.facturadebitoimputacionpendiente(motivo, facturadebitoimputacionpendientecc, anio, idrecibo, nrocuentacgasto, idcentrofacturadebitoimputacionpendiente, centro, idplancobertura, idsubcapitulo, idfacturadebitoimputacionpendie, nroregistro, fidtipo, idcapitulo, idmotivodebitofacturacion, importedebito, idpractica, idnomenclador, nroorden, idprestador, fdfecha) VALUES (fila.motivo, fila.facturadebitoimputacionpendientecc, fila.anio, fila.idrecibo, fila.nrocuentacgasto, fila.idcentrofacturadebitoimputacionpendiente, fila.centro, fila.idplancobertura, fila.idsubcapitulo, fila.idfacturadebitoimputacionpendie, fila.nroregistro, fila.fidtipo, fila.idcapitulo, fila.idmotivodebitofacturacion, fila.importedebito, fila.idpractica, fila.idnomenclador, fila.nroorden, fila.idprestador, fila.fdfecha);
    END IF;
    RETURN fila;
    END;
    $function$
