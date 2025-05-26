CREATE OR REPLACE FUNCTION public.asentarcomprobantefacturaciongenerico_v2()
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES    
montocuentacorriente Double precision;
idinformefacturacion  integer;
eltipoinfo INTEGER; 
elidconcepto INTEGER; 
einrocuenta INTEGER;

--REGISTROS
rfactventa RECORD;
elcomprobante RECORD;
esjubpen RECORD; 
elmovimiento RECORD;
rdatosnoafil RECORD;
rdatoscliente RECORD;
rorigenctacte RECORD;

--CURSORES
cfactventagenerico CURSOR for SELECT * FROM tempfacturaventa;
rusuario record;
elidusuario integer;
clientefact varchar;
nroclientefac varchar;
tipodocclientefac bigint;
elidinformefacturaciontipo integer;
BEGIN
     
     elidinformefacturaciontipo = 11 ; -- vas 21/12/2018
    OPEN cfactventagenerico;
     FETCH cfactventagenerico INTO rfactventa;
   IF existecolumtemp('tempfacturaventa','verificacliente') THEN --Agrega Vivi para el facturador de turismo
          CREATE TEMP TABLE tempcliente (
           nrocliente character varying NOT NULL,
           barra bigint NOT NULL,
           idtipocliente bigint NOT NULL,
	       denominacion varchar NOT NULL,
           idcondicioniva bigint NOT NULL
           );
           INSERT INTO tempcliente ( nrocliente  , barra  ,idtipocliente  , idcondicioniva,denominacion )
                  VALUES(rfactventa.nrodoc,1,6,1,rfactventa.vcdenominacion);
           SELECT INTO clientefact * FROM verificaingresacliente();
           nroclientefac = split_part( clientefact ,'|',1);
           tipodocclientefac = split_part( clientefact ,'|',2);
           UPDATE tempfacturaventa SET nrodoc = nroclientefac , tipodoc = tipodocclientefac
           WHERE nrofactura = rfactventa.nrofactura AND tipocomprobante = rfactventa.tipocomprobante AND
                 nrosucursal = rfactventa.nrosucursal AND tipofactura = rfactventa.tipofactura;
           DROP TABLE tempcliente;
     END IF;
     IF existecolumtemp('tempfacturaventa','idinformefacturaciontipo') THEN
                elidinformefacturaciontipo = rfactventa.idinformefacturaciontipo; -- vas 21/12/2018

     END IF;


     SELECT INTO elcomprobante * FROM  asentarcomprobantefacturacion() as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);
     
     /* Se guarda la informacion del usuario que genero el comprobante */
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF not found THEN
             elidusuario = 25;
     ELSE
             elidusuario = rusuario.idusuario;
     END IF;
    
     INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
     VALUES   (elcomprobante.tipocomprobante,elcomprobante.nrosucursal,elcomprobante.nrofactura, elcomprobante.tipofactura,elidusuario,elcomprobante.nrofactura);


 

   UPDATE facturaventa  SET fechaemision = rfactventa.fechaemision
         
   WHERE nrofactura = elcomprobante.nrofactura AND tipocomprobante = elcomprobante.tipocomprobante AND 
         nrosucursal = elcomprobante.nrosucursal AND tipofactura = elcomprobante.tipofactura;

/*KR 06-07-21 Comento todo esto, ahora desde el SP sys_generar_movimientoctacte SE generan los movimientos. El mismo se llama en el sp que genera el comprobante asentarcomprobantefacturacion. 

     IF (rfactventa.ctacte )THEN

	--MaLaPi 12-12-2017 Verifico en que tabla deberian estar las deudas y pagos. 
	CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
	INSERT INTO tempcliente(nrocliente,barra) VALUES(rfactventa.nrodoc,rfactventa.barra);
	SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2) as clavepersonactacte 
		FROM (
		SELECT verifica_origen_ctacte() as origen 
		) as t;
         DROP TABLE tempcliente;
	-- MaLaPi 13-12-2017 Si se trata de un cliente o un prestado, uso un sp diferente para generar el movimiento de cta.cte
	IF rorigenctacte.origentabla = 'prestadorctacte' OR rorigenctacte.origentabla = 'clientectacte' THEN 

		UPDATE tempfacturaventa SET nrofactura = elcomprobante.nrofactura,tipocomprobante = elcomprobante.tipocomprobante,
		              nrosucursal = elcomprobante.nrosucursal,tipofactura = elcomprobante.tipofactura
                 		WHERE nrofactura = rfactventa.nrofactura AND tipocomprobante = rfactventa.tipocomprobante AND
				nrosucursal = rfactventa.nrosucursal AND tipofactura = rfactventa.tipofactura;


		SELECT INTO idinformefacturacion asentarcomprobantefacturaciongenerico_generactacte()::bigint;
		
	-- KR 18-12-17 no corresponde ser llamado ya el sp anterior genera los movimientos correspondientes
--	PERFORM generardeudaordenesinstitucion(idinformefacturacion);
	
	ELSE 
		
	     --  1 - creo el informe de facturacion
             -- 2 registro la deuda
             -- Creo el informe de facturacion
       

           SELECT INTO elmovimiento *, CASE WHEN tipomovimiento ILIKE '%Pago%' THEN -1 ELSE 1 END AS elsigno
                   FROM tipofacturatipomovimiento WHERE tipofactura= elcomprobante.tipofactura;
           IF FOUND  THEN --se encontro el movimiento 
                      
                -- Verifico si viene seteado el concepto sino por defecto es asistencial
                elidconcepto = 387; einrocuenta = 10311;
                IF existecolumtemp('tempfacturaventa','idconcepto') THEN --Agrega Vivi 21/12/2018 para que la deuda de los comprobantes del camping queden en turismo
                IF (rfactventa.idconcepto=360) THEN 
                        elidconcepto = 360;
                        einrocuenta = 10333; 
                END IF;

           END IF;
        

           IF elmovimiento.tipomovimiento ILIKE '%Deuda%' THEN 

             SELECT INTO montocuentacorriente  sum(monto) * elmovimiento.elsigno
             FROM facturaventacupon NATURAL JOIN valorescaja 
             WHERE   idformapagotipos = 3 AND
                     nrofactura = elcomprobante.nrofactura AND 
                     tipocomprobante = elcomprobante.tipocomprobante AND 
                     nrosucursal = elcomprobante.nrosucursal AND
                     tipofactura = elcomprobante.tipofactura;

             SELECT INTO idinformefacturacion * FROM  crearinformefacturacion(rfactventa.nrodoc,rfactventa.barra,elidinformefacturaciontipo); -- vas 21/12/2018
        
             INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
                 (SELECT centro(), idinformefacturacion, idconcepto, cantidad, SUM(importe) as importe,  descripcion
                  FROM itemfacturaventa
                  WHERE  nrofactura = elcomprobante.nrofactura AND 
                         tipocomprobante = elcomprobante.tipocomprobante AND 
                         nrosucursal = elcomprobante.nrosucursal AND
                         tipofactura = elcomprobante.tipofactura
                  GROUP BY centro(), idinformefacturacion,idconcepto,cantidad,descripcion

                        );
                  UPDATE informefacturacion  SET
                      nrofactura = elcomprobante.nrofactura ,
                      tipocomprobante = elcomprobante.tipocomprobante ,
                      nrosucursal = elcomprobante.nrosucursal ,
                      tipofactura = elcomprobante.tipofactura,
                      idtipofactura = elcomprobante.tipofactura,
                      idformapagotipos = 3
                   WHERE idcentroinformefacturacion = centro() and  nroinforme = idinformefacturacion;
    
                IF (rfactventa.barra < 100) THEN 
                          INSERT INTO cuentacorrientedeuda (
                                      idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,
                                      nrocuentac,importe,idcomprobante,saldo, idconcepto, nrodoc, idcentrodeuda)VALUES
                                      (21,rfactventa.barra,concat(rfactventa.nrodoc,rfactventa.barra::varchar), rfactventa.fechaemision,
                          concat('Emision ',elcomprobante.tipofactura,' ',elcomprobante.tipocomprobante ,' ', elcomprobante.nrosucursal::varchar
                          ,' ',elcomprobante.nrofactura::varchar),
                          einrocuenta,montocuentacorriente, (idinformefacturacion*100)+centro(),
                          montocuentacorriente,elidconcepto,rfactventa.nrodoc,centro() );
                ELSE 
        	          SELECT INTO eltipoinfo dartipoinformecliente(rfactventa.nrodoc,rfactventa.barra,rfactventa.tipofactura);
                          IF (eltipoinfo <>11) THEN
			        UPDATE informefacturacion SET idinformefacturaciontipo=eltipoinfo
				WHERE nroinforme=idinformefacturacion AND idcentroinformefacturacion=centro();
		          END IF;
/*KR 06-07-21 Al parecer esto no se esta haciendo, hice esta consulta select * from informefacturacionestado  where descripcion ilike '%Generado desde asentarcomprobantefacturaciongenerico x deuda cliente%' and fechaini>'2020-06-01' y no me dio resultados, la ultima vez fue en el 2018 */
                          PERFORM generardeudaordenesinstitucion(idinformefacturacion); 

                          PERFORM  cambiarestadoinformefacturacion(idinformefacturacion,centro(),4,
                                   'Generado desde asentarcomprobantefacturaciongenerico x deuda cliente' );
             
         

                END IF;

      
       ELSE -- ES un pago
                   SELECT INTO montocuentacorriente  sum(monto) * elmovimiento.elsigno
                   FROM facturaventacupon NATURAL JOIN valorescaja 
                   WHERE nrofactura = elcomprobante.nrofactura AND 
                   tipocomprobante = elcomprobante.tipocomprobante AND 
                   nrosucursal = elcomprobante.nrosucursal AND
                   tipofactura = elcomprobante.tipofactura;
                   IF (rfactventa.barra <100) THEN 
   

                         INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,
                                             movconcepto,nrocuentac,importe,idcomprobante,saldo,nrodoc,idconcepto)
                         VALUES(51,rfactventa.barra,concat(rfactventa.nrodoc,rfactventa.barra::varchar),rfactventa.fechaemision,
                                concat('Emision ',elcomprobante.tipofactura,' ',elcomprobante.tipocomprobante , elcomprobante.nrosucursal::varchar
                                ,elcomprobante.nrofactura::varchar),einrocuenta,
                                montocuentacorriente,(elcomprobante.nrofactura*100)+elcomprobante.nrosucursal,
                                montocuentacorriente,rfactventa.nrodoc,elidconcepto);

                   ELSE 
                  
                          SELECT INTO rdatoscliente *,concat(cuitini,cuitmedio,cuitfin) as elidctacte
                          FROM cliente NATURAL JOIN clientectacte
                          WHERE cliente.nrocliente=rfactventa.nrodoc AND cliente.barra=rfactventa.barra;
                          IF FOUND THEN
                                  INSERT INTO ctactepagonoafil(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,
                                         nrocuentac,importe,idcomprobante,saldo,nrodoc)
                                   VALUES(51,rfactventa.barra,rdatoscliente.elidctacte::varchar,rfactventa.fechaemision,
                                          concat('Emision ',elcomprobante.tipofactura,' ', to_char(elcomprobante.nrosucursal, '0000')
                                          , '-' ,  to_char(elcomprobante.nrofactura, '00000000')) ,
                                          10311, montocuentacorriente,(elcomprobante.nrofactura*100)+elcomprobante.nrosucursal,
                                          montocuentacorriente,rfactventa.nrodoc);

                
                                  INSERT INTO ctactepagocliente(idcomprobantetipos,idclientectacte,fechamovimiento,movconcepto,
                                              nrocuentac,importe,idcomprobante,saldo)
                                  VALUES(51,rdatoscliente.idclientectacte,rfactventa.fechaemision,
                                          concat('Emision ',elcomprobante.tipofactura,' ', to_char(elcomprobante.nrosucursal, '0000')
                                          , '-' ,  to_char(elcomprobante.nrofactura, '00000000')) ,
                                          10311, montocuentacorriente,(elcomprobante.nrofactura*100)+elcomprobante.nrosucursal,
                                          montocuentacorriente);

                     END IF; 

               END IF; 
     
            END IF; --DE SI ES DEUDA O PAGO EL MOVIMIENTO
         END IF; -- HAY Un tipo movimiento en la tabla

	END IF; -- FIN de IF rorigenctacte.origentabla = 'prestadorctacte' OR rorigenctacte.origentabla = 'clientectacte' THEN 

       END IF;--hay un movimiento en la cta cte 
*/
   IF  elcomprobante.tipofactura = 'LI' THEN 
          /* Dejo la LI en estado sincronizado */
         INSERT INTO multivac.facturaventa_migrada(nrofactura, tipocomprobante, nrosucursal,
            tipofactura,centro, iditem, fechamigracion, estaanulada)
            VALUES(elcomprobante.nrofactura, elcomprobante.tipocomprobante, elcomprobante.nrosucursal, elcomprobante.tipofactura, centro(), 0, now(),0 );

   END IF; 
   SELECT INTO  esjubpen * FROM persona WHERE nrodoc=rfactventa.nrodoc AND tipodoc =rfactventa.barra;

/*Dani comento 01/11/19 para que no se genere mas la bonificacion de IVA para Jubilados/Pendionados  desde el facturador generico*/
 /*             IF (esjubpen.barra=35 or esjubpen.barra=36) THEN

   PERFORM modificaritemfacturajubilados(elcomprobante.tipocomprobante::integer,elcomprobante.nrosucursal::integer,elcomprobante.nrofactura,elcomprobante.tipofactura::varchar
);

-- CS 2018-04-26
-- Para crear los asientos de las facturas
/*   
   -- formato: 'FA|1|20|1894'
   PERFORM asientogenericofacturaventa_crear(concat(elcomprobante.tipofactura,'|',elcomprobante.tipocomprobante,'|',elcomprobante.nrosucursal,'|',elcomprobante.nrofactura));
*/
------------------------------------------
              END IF;
*/

    RETURN NEXT elcomprobante;
END;
$function$
