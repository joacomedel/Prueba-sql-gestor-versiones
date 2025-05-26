CREATE OR REPLACE FUNCTION public.insertarreintegro2(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Es llamado desde mesa de entrada cuando se da
entrada a un reintegro, se le pasa como parametro
el idrecepcion.
Llena la tabla reintegro, setea el idcentroregional en 1
(Neuquen). Llena el resto de los campos con excepcion de
los campos tipoformapago,nroordenpago y rimporte.
Inserta el reintegro en la tabla restados como pendiente
y carga las prestaciones del reintegro la tabla reintegroprestacion*/
DECLARE
    	idrec alias for $1;
	tipopago alias for $2;
        tipoformapagodef reintegro.tipoformapago%TYPE;
	rrec RECORD;
	rcuentas RECORD;
	aux RECORD;
	nroreint RECORD;
	
    rrecreintegro CURSOR FOR
                  SELECT persona.nrodoc as nrodoc
                             ,persona.tipodoc as tipodoc
                             ,extract('year' from fecha) as anio
                             ,persona.barra
                             ,localidad
                             ,nombreaf
                             ,apellidoaf
                             ,fecha
                             ,idestudio
                             ,cantidad
                             ,centroregional.idcentroregional
                             FROM recepcion NATURAL JOIN recreintegro
                             NATURAL JOIN reintegroestudio
                             JOIN centroregional on centroregional.crdescripcion = recreintegro.localidad
                             JOIN persona USING(nrodoc,barra)
    WHERE idrecepcion = idrec;

BEGIN
    	IF (tipopago = 0) THEN 
		tipoformapagodef:=NULL;
        ELSE
                tipoformapagodef:=tipopago;
        END IF;

	OPEN rrecreintegro;	
	FETCH rrecreintegro INTO rrec;
	WHILE  found LOOP
	
       SELECT INTO aux * FROM reintegro where idrecepcion = idrec;
       IF NOT FOUND THEN
       SELECT INTO rcuentas * FROM cuentas  WHERE rrec.nrodoc = cuentas.nrodoc AND rrec.tipodoc = cuentas.tipodoc;
 	    INSERT INTO reintegro (anio,idcentroregional,tipodoc,nrodoc,tipocuenta,nrocuenta,tipoformapago,nroordenpago,rimporte,rfechaingreso,idrecepcion,nrooperacion)
             VALUES (rrec.anio,rrec.idcentroregional,rrec.tipodoc,rrec.nrodoc,rcuentas.tipocuenta,rcuentas.nrocuenta,tipoformapagodef,null,null,rrec.fecha,idrec,null);

       SELECT INTO nroreint currval(('reintegro_nroreintegro_seq'::text)) as nroreintegro;

       INSERT INTO restados
       (fechacambio,nroreintegro,tipoestadoreintegro,anio,observacion)
       VALUES(rrec.fecha,nroreint.nroreintegro,1,rrec.anio,'Desde mesa de entrada');

       INSERT INTO reintegroprestacion
       (nroreintegro,anio,tipoprestacion,importe,observacion,
       prestacion,cantidad)
       VALUES(nroreint.nroreintegro,rrec.anio,rrec.idestudio,0,'Desde mesa de entrada',null,rrec.cantidad);

       ELSE
       INSERT INTO reintegroprestacion
       (nroreintegro,anio,tipoprestacion,importe,observacion,
       prestacion,cantidad)
       VALUES(nroreint.nroreintegro,rrec.anio,rrec.idestudio,0,'Desde mesa de entrada',null,rrec.cantidad);

       END IF;
	FETCH rrecreintegro INTO rrec;
	END LOOP;
	CLOSE rrecreintegro ;
	RETURN 'true';
END;$function$
