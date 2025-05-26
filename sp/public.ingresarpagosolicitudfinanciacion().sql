CREATE OR REPLACE FUNCTION public.ingresarpagosolicitudfinanciacion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
 * Datos entrada: temppagoprestamo (
*				  tipodoc INTEGER  NOT NULL,
*				  idbanco INTEGER,
*				  fechaingreso DATE,
*				  nrooperacion VARCHAR NOT NULL,
*				  nrodoc VARCHAR NOT NULL,
*				  concepto VARCHAR NOT NULL,
*				  idsolicitudfinanciacion INTEGER NOT NULL,
*				  idcentrosolicitudfinanciacion INTEGER NOT NULL,
*				  importetotal float NULL,
*                 intereses  float NUL, ML me los va a enviar desde la interfase
*				  idlocalidad INTEGER NULL,
*				  idprovincia INTEGER NULL,
*				  formapagotipos INTEGER NULL,
*				  idusuario INTEGER);
*
* Se guarda la informacion del pago del prestamo
* Actualizar el estado de la solicitud del prestamo a estado Pagado
* Se crea el informe de facturacionfechas
* Se actualiza el informe de facturacion a estado 3=facturable
* Tablas que se modifican: Informefacturacion,informefacturacionestado,informefacturacionitem,informefacturacionsolicitudfinanciacion,solicitudfinanciamientoestado
*/

DECLARE

		    elpagoprestamo record;
		    rcliente record;
		    informeF integer;
		    nrocuentacontablecuota integer;
		    nrocuentacontableintereses integer;
                    nrocuentacontableivaintereses integer;
	        resp boolean;
BEGIN
             nrocuentacontablecuota = '40605'; --------VER CC
             nrocuentacontableintereses = '40605'; --------VER CC
             nrocuentacontableivaintereses = '20821'; --Configuro Malapi

             -- Recupero los datos de la tabla temporal
             SELECT * INTO elpagoprestamo  FROM temppagoprestamo;
            -- Busco los datos de la persona que solicito el prestamo
             SELECT INTO rcliente * FROM persona WHERE persona.nrodoc=elpagoprestamo.nrodoc and persona.tipodoc=elpagoprestamo.tipodoc;


             -- Creo el informe de facturacion
             SELECT INTO informeF * FROM crearinformefacturacion(rcliente.nrodoc,rcliente.barra, 4 );
             INSERT INTO  informefacturacionsolicitudfinanciacion(nroinforme,idcentroinformefacturacion,idsolicitudfinanciacion,idcentrosolicitudfinanciacion )
             VALUES(informeF,Centro(),elpagoprestamo.idsolicitudfinanciacion,elpagoprestamo.idcentrosolicitudfinanciacion);

             -- Creo los item del informe de facturacion
             CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR,idiva INTEGER);
             -- Modificado 23/04/2010 el importe total del prestamo no se factura , SOLO SE FACTURA LOS INTERESES
             -- Malapi 19/09/2016 Tambien hay que facturar el iva de los intereses
--             INSERT INTO ttinformefacturacionitem (	nroinforme ,nrocuentac ,cantidad ,importe ,descripcion)
--             VALUES (informeF,nrocuentacontablecuota,1,elpagoprestamo.importetotal,' Valor de prestamo');
             INSERT INTO ttinformefacturacionitem (	nroinforme ,nrocuentac ,cantidad ,importe ,descripcion,idiva)
             VALUES (informeF,nrocuentacontableintereses,1,elpagoprestamo.intereses,' Intereses',2);
--CS 2017-01-16 Lo comento para que no se duplique el IVA
--             INSERT INTO ttinformefacturacionitem (nroinforme ,nrocuentac ,cantidad ,importe ,descripcion,idiva)
--             VALUES (informeF,nrocuentacontableivaintereses,1,round((elpagoprestamo.intereses*0.21)::numeric,3),'Iva de los Intereses',2);

             SELECT INTO resp * FROM insertarinformefacturacionitem();

             -- Cambio el estado del informe de facturacion 3=facturable
             UPDATE informefacturacionestado
             SET fechafin=NOW()
             WHERE nroinforme=informeF and idcentroinformefacturacion=Centro() and fechafin is null;

             INSERT INTO informefacturacionestado (nroinforme,idcentroinformefacturacion,idinformefacturacionestadotipo,fechaini)
             VALUES(informeF,Centro(),3,NOW());

             -- Cambio de estado de la solicitud de financiacion a 5=pagado
             UPDATE solicitudfinanciacionestado
             SET fechafin = NOW()
             WHERE idsolicitudfinanciacion= elpagoprestamo.idsolicitudfinanciacion and
             idcentrosolicitudfinanciacion=elpagoprestamo.idcentrosolicitudfinanciacion and fechafin is null;
             
             INSERT INTO solicitudfinanciacionestado(idsolicitudfinanciacion, idcentrosolicitudfinanciacion,fechaini,idusuario,idsolicitudfinanciacionestadotipo,sfedescripcion)
             VALUES(elpagoprestamo.idsolicitudfinanciacion,elpagoprestamo.idcentrosolicitudfinanciacion,NOW(),elpagoprestamo.idusuario,5, 'Generado Automaticamente en ingresarpagosolicitudfinanciacion  ');

RETURN 'true';
END;
$function$
