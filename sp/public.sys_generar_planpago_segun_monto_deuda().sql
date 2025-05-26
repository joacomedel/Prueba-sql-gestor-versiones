CREATE OR REPLACE FUNCTION public.sys_generar_planpago_segun_monto_deuda()
 RETURNS void
 LANGUAGE plpgsql
AS $function$/*
Genera planes de pago desde planillas excel que se cargan en la base de datos 

Conuslta para controlar que la deuda que se proyecta, se corresponde con lo que esta en los excel entregados
select (totalresultado - round(importetotal::numeric,2)) as dif,* from (
SELECT sum(saldo) as importetotal, ppmnroafiliado,totalresultado
FROM sys_planes_pago_masivo_config
NATURAL JOIN (
SELECT iddeuda,idcentrodeuda, ppmnroafiliado,concat(fv.tipofactura,' ',desccomprobanteventa,' ',lpad(fv.nrosucursal,4,'0'),'-',lpad(fv.nrofactura,8,'0')) as comprobante,ccd.importe, ccd.saldo, ccd.movconcepto  
FROM facturaventa fv 
JOIN tipocomprobanteventa tcv on (fv.tipocomprobante=tcv.idtipo) JOIN informefacturacion if USING(nrofactura, tipocomprobante, nrosucursal, tipofactura)
JOIN cuentacorrientedeuda ccd on (ccd.idcomprobante= (if.nroinforme*100)+if.idcentroinformefacturacion AND ccd.idcomprobantetipos=21 )
JOIN sys_planes_pago_masivo ON ppmcomprobante = concat(fv.tipofactura,' ',desccomprobanteventa,' ',lpad(fv.nrosucursal,4,'0'),'-',lpad(fv.nrofactura,8,'0'))
WHERE true AND nullvalue(ppmborrado::timestamp) 
) as deuda 
-- USING(ppmnroafiliado) 
GROUP BY ppmnroafiliado,totalresultado
) as t;
*/
DECLARE
	cpagos refcursor;
	cplanespago refcursor;
    ralerta RECORD;
	runplanpago RECORD;
	vrespuesta varchar;
	
	vprimero boolean;
	vprestamo INTEGER;
  

BEGIN

--Se toman los parametros de configuracion puestos en http://glpi.sosunc.org.ar/front/ticket.form.php?id=4975
--Consumo Asistencial  rango de $5.000 - $6.000 se cargaran 2 cuotas.
--Consumo Asistencial  rango de $6.000 - $10.000 se cargaran 3 cuotas.
--Consumo Asistencial  rango de $10.000 - $15.000 se cargaran 4 cuotas.
--Consumo Asistencial  rango de $15.000 - $25.000 se cargaran 6 cuotas.
--Consumo Asistencial  rango de $25.000 - $30.000 se cargaran 8 cuotas.

CREATE TEMP TABLE TEMPPAGOCTACTE ( IDPAGOTIPO INTEGER, IDRECIBO BIGINT,  CENTRO INTEGER,  IDFORMAPAGOTIPOS INTEGER,  CONCEPTOPAGO VARCHAR,  FECHAINGRESO DATE,  NRODOC VARCHAR,  TIPODOC INTEGER,  IMPORTEENLETRAS VARCHAR,  IMPORTEAPAGAR DOUBLE PRECISION, IDBANCO INTEGER,  IDLOCALIDAD INTEGER, IDPROVINCIA  INTEGER,  NROOPERACION VARCHAR, NROCUENTAC VARCHAR) ;   
CREATE TEMP TABLE PAGOCUENTACORRIENTE (   IDMOVIMIENTO BIGINT,   CENTRO INTEGER,   IDCOMPROBANTETIPOS INTEGER,   TIPODOC INTEGER ,   NRODOC VARCHAR ,   FECHAMOVIMIENTO DATE,   MOVCONCEPTO VARCHAR,   NROCUENTAC VARCHAR,  IMPORTE DOUBLE PRECISION,   SIGNO INTEGER,   IDCOMPROBANTE INTEGER,   IDMOVCANCELA BIGINT   ) WITHOUT OIDS;
--INSERT INTO pagocuentacorriente(idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo)	VALUES(0,NULL,'223790041',CURRENT_DATE,'Generacion de Plan de Pagos para la deuda','10321','29815.27',-1);
--INSERT INTO pagocuentacorriente(idmovimiento,centro)	VALUES(356162,1);
--INSERT INTO pagocuentacorriente(idmovimiento,centro)	VALUES(356982,1);
--INSERT INTO pagocuentacorriente(idmovimiento,centro)	VALUES(357083,1);
--INSERT INTO pagocuentacorriente(idmovimiento,centro)	VALUES(357084,1);
--INSERT INTO pagocuentacorriente(idmovimiento,centro)	VALUES(357150,1);
CREATE TEMP TABLE TEMPCONFIGURACIONPRESTAMO (   TIPODOC INTEGER  NOT NULL,  CANTIDADCUOTAS INTEGER,  NRODOC VARCHAR NOT NULL,  IDSOLICITUDFINANCIACION INTEGER ,  IDCENTROSOLICITUDFINANCIACION INTEGER ,  IMPORTETOTAL FLOAT NULL,  INTERESES FLOAT NULL,  IMPORTEANTICIPO FLOAT NULL,  IDUSUARIO INTEGER,  IMPORTECUOTA FLOAT  NULL,  IDPRESTAMO BIGINT,  IDCENTROPRESTAMO INTEGER,  FECHAINIPAGO DATE NULL);
--INSERT INTO tempconfiguracionprestamo(fechainipago,importeanticipo,idusuario,tipodoc,cantidadcuotas,nrodoc,idsolicitudfinanciacion,idcentrosolicitudfinanciacion,importetotal,intereses,importecuota)  VALUES('2022-04-11','0.00',null,1,8,'22379004',NULL,NULL,'29815.27','0.000000','3726.91')


--Seteo el usuario que solicito el procesamiento Andrea Parra

PERFORM log_registrar_conexion(94,'desdebasededatos');



OPEN cplanespago FOR  SELECT * FROM sys_planes_pago_masivo_config 
WHERE nullvalue(ppmfechaprocesado) 
ORDER BY idplanespagomasivoconfig
LIMIT 50
;

FETCH cplanespago into runplanpago;
WHILE  found LOOP

OPEN cpagos FOR SELECT iddeuda,idcentrodeuda,0 as idcomprobantetipos,idctacte,tipodoc,nrodoc,totalresultado as importeplanpago,saldo as importedeuda,cantcuotas,importecuota
			FROM sys_planes_pago_masivo_config
			NATURAL JOIN (
				SELECT iddeuda,idcentrodeuda,ccd.idctacte,ccd.tipodoc,ccd.nrodoc, ppmnroafiliado,concat(fv.tipofactura,' ',desccomprobanteventa,' ',lpad(fv.nrosucursal,4,'0'),'-',lpad(fv.nrofactura,8,'0')) as comprobante,ccd.importe, ccd.saldo, ccd.movconcepto  
				FROM facturaventa fv 
				JOIN tipocomprobanteventa tcv on (fv.tipocomprobante=tcv.idtipo) JOIN informefacturacion if USING(nrofactura, tipocomprobante, nrosucursal, tipofactura)
				JOIN cuentacorrientedeuda ccd on (ccd.idcomprobante= (if.nroinforme*100)+if.idcentroinformefacturacion AND ccd.idcomprobantetipos=21 )
				JOIN sys_planes_pago_masivo ON ppmcomprobante = concat(fv.tipofactura,' ',desccomprobanteventa,' ',lpad(fv.nrosucursal,4,'0'),'-',lpad(fv.nrofactura,8,'0'))
				WHERE true AND nullvalue(ppmborrado::timestamp) 
			) as deuda 
			WHERE ppmnroafiliado = runplanpago.ppmnroafiliado;
                          
vprimero = true;


FETCH cpagos into ralerta;
WHILE  found LOOP

	IF vprimero THEN
	    vprimero = false;
		INSERT INTO pagocuentacorriente(idcomprobantetipos,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo)	
		VALUES(ralerta.idcomprobantetipos,ralerta.idctacte,CURRENT_DATE,'Generacion de Plan de Pagos para la deuda','10321',ralerta.importeplanpago,-1);
		INSERT INTO tempconfiguracionprestamo(fechainipago,importeanticipo,idusuario,tipodoc,cantidadcuotas,nrodoc,idsolicitudfinanciacion,idcentrosolicitudfinanciacion,importetotal,intereses,importecuota)  
		VALUES(CURRENT_DATE,'0.00',sys_dar_usuarioactual(),ralerta.tipodoc,ralerta.cantcuotas,ralerta.nrodoc,NULL,NULL,ralerta.importeplanpago,'0.000000',ralerta.importecuota);
	END IF;
		INSERT INTO pagocuentacorriente(idmovimiento,centro)	VALUES(ralerta.iddeuda,ralerta.idcentrodeuda);

FETCH cpagos into ralerta;
END LOOP;
close cpagos;
IF not vprimero THEN
       SELECT INTO vprestamo generarplanpagocuentacorriente() as idprestamo;
       vrespuesta = concat(vrespuesta,'|',runplanpago.ppmnroafiliado,'-',vprestamo);
       PERFORM plandepago_genera_procesa_sf();
        --MaLapi 12-04-2022 limpio las tablas temporales usadas en el proceso
     DROP TABLE reciboautomaticoctacte;
DELETE FROM TEMPPAGOCTACTE;
DELETE FROM PAGOCUENTACORRIENTE;
DELETE FROM TEMPCONFIGURACIONPRESTAMO;

END IF;

UPDATE sys_planes_pago_masivo_config SET ppmfechaprocesado = now() WHERE idplanespagomasivoconfig = runplanpago.idplanespagomasivoconfig;
RAISE NOTICE 'Termine de procesar (%),(%)',runplanpago.ppmnroafiliado,runplanpago.idplanespagomasivoconfig;




FETCH cplanespago into runplanpago;
END LOOP;
close cplanespago;

END;
$function$
