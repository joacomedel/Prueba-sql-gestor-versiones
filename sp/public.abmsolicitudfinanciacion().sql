CREATE OR REPLACE FUNCTION public.abmsolicitudfinanciacion()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
 --RECORD 
   rusuario RECORD;
   rfactventa RECORD;
   rsolfinanciacion RECORD;
   rlafactura RECORD;
   rfvturismo RECORD;
   rconfigprestamo RECORD;

--VARIABLES
  vmesingreso INTEGER;
  vidsolfinanciacion VARCHAR;
  vcodprestamo INTEGER;

BEGIN

 SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
 IF NOT FOUND THEN 
         rusuario.idusuario = 25;
 END IF;
--Solo se pueden cancelar prestamos y solicitudes si no fueron pagadas
 SELECT INTO rconfigprestamo * FROM tempconfiguracionprestamo  NATURAL JOIN cuentacorrientedeudafacturaventa JOIN cuentacorrientedeuda USING(iddeuda, idcentrodeuda) LEFT JOIN cuentacorrientedeudapago USING(iddeuda, idcentrodeuda) 
                               WHERE nullvalue(cuentacorrientedeudapago.iddeuda);
 IF (NOT nullvalue(rconfigprestamo.cancelar) AND rconfigprestamo.cancelar )  THEN  
--Cancelo la solicitud
   INSERT INTO solicitudfinanciacionestado(idsolicitudfinanciacion,idcentrosolicitudfinanciacion,fechaini,idusuario,idsolicitudfinanciacionestadotipo,sfedescripcion)
    VALUES(rconfigprestamo.idsolicitudfinanciacion,rconfigprestamo.idcentrosolicitudfinanciacion,NOW(),rusuario.idusuario,4,concat('Cancelado al ser anulado el comprobante de facturacion: ',to_char(rconfigprestamo.nrosucursal, '0000'),'  ',
to_char(rconfigprestamo.nrofactura, '00000000'),' Generado Automaticamente en abmsolicitudfinanciacion. '));

--si es un prestamo de turismo, lo anulo 
   UPDATE prestamoestado SET pefechafin= now() WHERE idprestamo= rconfigprestamo.idprestamo and idcentroprestamo= rconfigprestamo.idcentroprestamo;
   INSERT INTO prestamoestado(idprestamo,idcentroprestamo,idprestamoestadotipos)VALUES (rconfigprestamo.idprestamo,rconfigprestamo.idcentroprestamo,3);

   --cancelo la deuda
   UPDATE cuentacorrientedeuda SET importe= 0, saldo =   0, movconcepto=  concat('Movimiento cancelado al anularse el comprobante de facturacion: ',to_char(rconfigprestamo.nrosucursal, '0000'),'  ',to_char(rconfigprestamo.nrofactura, '00000000'),'.  ',movconcepto)
   FROM (SELECT iddeuda, idcentrodeuda, idprestamocuotas *10 + idcentroprestamocuota AS elidcomprobante 
         FROM cuentacorrientedeuda JOIN prestamocuotas ON(cuentacorrientedeuda.idcomprobante = prestamocuotas.idprestamocuotas *10 + prestamocuotas.idcentroprestamocuota)
         WHERE idprestamo = rconfigprestamo.idprestamo AND idcentroprestamo= rconfigprestamo.idcentroprestamo)   AS T
         WHERE cuentacorrientedeuda.iddeuda = T.iddeuda AND cuentacorrientedeuda.idcentrodeuda = T.idcentrodeuda;
  
   INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,idcentropago)
  SELECT idcomprobantetipos,tipodoc,idctacte,CURRENT_TIMESTAMP,concat('Movimiento cancelado al anularse el comprobante de facturacion: ',to_char(rconfigprestamo.nrosucursal, '0000'),'  ',to_char(rconfigprestamo.nrofactura, '00000000')) ,nrocuentac, (-1)*importe,idcomprobante,0,idconcepto,nrodoc,centro()
         FROM cuentacorrientedeuda JOIN prestamocuotas ON(cuentacorrientedeuda.idcomprobante = prestamocuotas.idprestamocuotas *10 + prestamocuotas.idcentroprestamocuota)
         WHERE idprestamo = rconfigprestamo.idprestamo AND idcentroprestamo= rconfigprestamo.idcentroprestamo;
        

 ELSE
   CREATE TEMP TABLE tempsolicitudfinanciacion (   tipodoc INTEGER  NOT NULL,  
                                nroingresome INTEGER,
				nrodoc VARCHAR NOT NULL,
				sfdescripcion VARCHAR NOT NULL,
				fechasolicitud DATE NULL,
				fechaingresome DATE NULL,
				idusuario INTEGER,
				montosolicitado FLOAT  NULL);
   CREATE TEMP TABLE tempsolicitudfinanciacionbeneficiario( 
		  nrodoc VARCHAR NOT NULL ,
		  tipodoc INTEGER  NOT NULL
		);

   CREATE TEMP TABLE pagocuentacorriente (idmovimiento BIGINT,   
                                          centro INTEGER,   
                                          idcomprobantetipos INTEGER,   
                                          tipodoc INTEGER ,   
                                          nrodoc VARCHAR ,   
                                          fechamovimiento DATE,   
                                          movconcepto VARCHAR,   
                                          nrocuentac VARCHAR,  
                                          importe DOUBLE PRECISION,   
                                          signo INTEGER,   
                                          idcomprobante INTEGER,   
                                          idmovcancela BIGINT   ) WITHOUT OIDS;

   SELECT into rfactventa * FROM tempfacturaventa;



   SELECT INTO rlafactura * FROM facturaventa WHERE nrofactura= rfactventa.nrofactura AND nrosucursal=rfactventa.nrosucursal AND tipocomprobante= rfactventa.tipocomprobante AND tipofactura=rfactventa.tipofactura;


   SELECT INTO vmesingreso extract('month' from now());



   INSERT INTO tempsolicitudfinanciacion(idusuario,tipodoc,nroingresome,nrodoc,sfdescripcion,fechasolicitud,fechaingresome,montosolicitado) 
 VALUES(rusuario.idusuario,rfactventa.barra,vmesingreso,rfactventa.nrodoc, concat('Emision ',rfactventa.tipofactura,' ',
to_char(rconfigprestamo.nrosucursal, '0000'),'  ',to_char(rconfigprestamo.nrofactura, '00000000'),
'- Solicitud generada en caja al pagar en cta cte. SP abmsolicitudfinanciacion.'),current_date,current_date,rlafactura.importectacte);
		 
	
   INSERT INTO tempsolicitudfinanciacionbeneficiario(nrodoc,tipodoc) VALUES(rfactventa.nrodoc,rfactventa.barra);
  
   SELECT INTO vidsolfinanciacion * FROM generarsolicitudfinanciamiento();
  
   IF iftableexistsparasp('tempinforme') THEN  --ES turismo
   
     SELECT INTO rfvturismo  *,case when ctfechasalida <= date_trunc('month',ctfechasalida)::date + integer '14'
THEN  date_trunc('month',ctfechasalida)::date + integer '21'
ELSE  (date_trunc('month',ctfechasalida)::date + integer '21' + interval '1 month')::date END as fechavtocuotauno
     FROM tempinforme  NATURAL JOIN informefacturacionturismo NATURAL JOIN consumoturismo;
     RAISE NOTICE 'rfvturismo(%)', rfvturismo.fechavtocuotauno;
     UPDATE tempconfiguracionprestamo SET fvtocuotauno = rfvturismo.fechavtocuotauno;
     SELECT INTO vcodprestamo * FROM generarprestamocuotas(1);

   ELSE --Plan pago cuenta corriente

     INSERT INTO pagocuentacorriente(idcomprobantetipos,tipodoc,nrodoc,fechamovimiento,movconcepto,nrocuentac,importe,signo)	VALUES(0,rfactventa.barra,rfactventa.nrodoc,CURRENT_DATE,'Generacion de Plan de Pagos para la deuda desde sp abmsolicitudfinanciacion','10311',rlafactura.importectacte,-1);
     SELECT INTO vcodprestamo * FROM generarplanpagocuentacorriente();
     
   END IF; 
 
   RAISE NOTICE 'vcodprestamo(%)', vcodprestamo;
--vinculo la solicitud con el prestamo
   INSERT INTO prestamosolicitudfinanciacion (idprestamo,idcentroprestamo,idsolicitudfinanciacion,idcentrosolicitudfinanciacion)
                VALUES (vcodprestamo, centro(),split_part(vidsolfinanciacion, '-',1)::integer ,split_part(vidsolfinanciacion, '-',2)::integer);

   INSERT INTO solicitudfinanciacionestado(idsolicitudfinanciacion, idcentrosolicitudfinanciacion,fechaini,idusuario,idsolicitudfinanciacionestadotipo,sfedescripcion)
                VALUES(split_part(vidsolfinanciacion, '-',1)::integer,split_part(vidsolfinanciacion, '-',2)::integer,NOW(),rusuario.idusuario,6, 'Generado Automaticamente en abmsolicitudfinanciacion  ');

/*
   SELECT INTO rdeuda * FROM cuentacorrientedeuda JOIN prestamocuotas ON(cuentacorrientedeuda.idcomprobante = prestamocuotas.idprestamocuotas *10 + prestamocuotas.idcentroprestamocuota) WHERE idprestamo = vcodprestamo AND idcentroprestamo=centro();  
*/
  
   INSERT INTO cuentacorrientedeudafacturaventa(tipocomprobante,nrosucursal,nrofactura,tipofactura,iddeuda,idcentrodeuda)	
   SELECT rfactventa.tipocomprobante,rfactventa.nrosucursal,rfactventa.nrofactura,rfactventa.tipofactura,iddeuda,idcentrodeuda
       FROM cuentacorrientedeuda JOIN prestamocuotas ON(cuentacorrientedeuda.idcomprobante = prestamocuotas.idprestamocuotas *10 + prestamocuotas.idcentroprestamocuota) WHERE idprestamo = vcodprestamo AND idcentroprestamo=centro();  
   
 END IF;
   return TRUE;	
END;
$function$
