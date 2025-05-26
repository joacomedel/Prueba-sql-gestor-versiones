CREATE OR REPLACE FUNCTION public.asentarcomprobantefacturaciongenerico_v1()
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $function$
DECLARE

--VARIABLES    
montocuentacorriente Double precision;
idinformefacturacion  integer;
eltipoinfo INTEGER; 

--REGISTROS
rfactventa RECORD;
elcomprobante RECORD;
esjubpen RECORD; 
elmovimiento RECORD;
rdatosnoafil RECORD;
rdatoscliente RECORD;

--CURSORES
cfactventagenerico CURSOR for SELECT * FROM tempfacturaventa;
rusuario record;
elidusuario integer;
clientefact varchar;
nroclientefac varchar;
tipodocclientefac bigint;
BEGIN

    OPEN cfactventagenerico;
     FETCH cfactventagenerico INTO rfactventa;
   /*IF existecolumtemp('tempfacturaventa','verificacliente') THEN
          CREATE TABLE tempcliente (
           nrocliente character varying NOT NULL,
           barra bigint NOT NULL,
           idtipocliente bigint NOT NULL,

           idcondicioniva bigint NOT NULL
           );
           INSERT INTO tempcliente ( nrocliente  , barra  ,idtipocliente  , idcondicioniva )
                  VALUES(rfactventa.nrodoc,1,6,1);
           clientefact = SELECT verificarcliente();
           nroclientefac = split_part( clientefact ,'|',1);
           tipodocclientefac = split_part( clientefact ,'|',2);
           UPDATE tempfacturaventa SET nrodoc = nroclientefac , tipodoc = tipodocclientefac
           WHERE nrofactura = rfactventa.nrofactura AND tipocomprobante = rfactventa.tipocomprobante AND
                 nrosucursal = rfactventa.nrosucursal AND tipofactura = rfactventa.tipofactura;

     END IF;
*/

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


     IF (rfactventa.ctacte )THEN
          --  1 - creo el informe de facturacion
          -- 2 registro la deuda
 	      -- Creo el informe de facturacion
       

       SELECT INTO elmovimiento *, CASE WHEN tipomovimiento ILIKE '%Pago%' THEN -1 ELSE 1 END AS elsigno
                   FROM tipofacturatipomovimiento WHERE tipofactura= elcomprobante.tipofactura;
       IF FOUND  THEN --se encontro el movimiento 
                      
      
        

         IF elmovimiento.tipomovimiento ILIKE '%Deuda%' THEN 

             SELECT INTO montocuentacorriente  sum(monto) * elmovimiento.elsigno
          FROM facturaventacupon NATURAL JOIN valorescaja 
          WHERE   idformapagotipos = 3 AND
                     nrofactura = elcomprobante.nrofactura AND 
                 tipocomprobante = elcomprobante.tipocomprobante AND 
                 nrosucursal = elcomprobante.nrosucursal AND
                 tipofactura = elcomprobante.tipofactura;

          SELECT INTO idinformefacturacion * FROM  crearinformefacturacion(rfactventa.nrodoc,rfactventa.barra,11);
        
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
                (21,rfactventa.barra,concat(rfactventa.nrodoc,rfactventa.barra::varchar), now(),
                concat('Emision Factura ',elcomprobante.tipocomprobante , elcomprobante.nrosucursal::varchar
                ,elcomprobante.nrofactura::varchar),
                10311,montocuentacorriente, (idinformefacturacion*100)+centro(),
                 montocuentacorriente,387,rfactventa.nrodoc,centro() );
         ELSE 
        	SELECT INTO eltipoinfo dartipoinformecliente(rfactventa.nrodoc,rfactventa.barra,rfactventa.tipofactura);
                IF (eltipoinfo <>11) THEN
			UPDATE informefacturacion SET idinformefacturaciontipo=eltipoinfo
				WHERE nroinforme=idinformefacturacion AND idcentroinformefacturacion=centro();
		END IF;

               PERFORM generardeudaordenesinstitucion(idinformefacturacion); 

                PERFORM  cambiarestadoinformefacturacion(idinformefacturacion,centro(),4,
                              'Generado desde asentarcomprobantefacturaciongenerico x deuda cliente' );
             
         

          END IF;
      
       ELSE -- ES un pago
                   SELECT INTO montocuentacorriente  sum(monto) * elmovimiento.elsigno
                      FROM facturaventacupon NATURAL JOIN valorescaja 
                         WHERE                        nrofactura = elcomprobante.nrofactura AND 
                 tipocomprobante = elcomprobante.tipocomprobante AND 
                 nrosucursal = elcomprobante.nrosucursal AND
                 tipofactura = elcomprobante.tipofactura;
                IF (rfactventa.barra <100) THEN 

                   INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,
                      movconcepto,nrocuentac,importe,idcomprobante,saldo,nrodoc)
                   VALUES(51,rfactventa.barra,concat(rfactventa.nrodoc,rfactventa.barra::varchar),now(),
                     concat('Nota Credito ',elcomprobante.tipocomprobante , elcomprobante.nrosucursal::varchar
                    ,elcomprobante.nrofactura::varchar),10311,
                      montocuentacorriente,(elcomprobante.nrofactura*100)+elcomprobante.nrosucursal,
                      montocuentacorriente,rfactventa.nrodoc);

                ELSE 
                  
                 SELECT INTO rdatoscliente *,concat(cuitini,cuitmedio,cuitfin) as elidctacte
                           FROM cliente NATURAL JOIN clientectacte
                           WHERE cliente.nrocliente=rfactventa.nrodoc AND cliente.barra=rfactventa.barra;
                  IF FOUND THEN
                    INSERT INTO ctactepagonoafil(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,
                    nrocuentac,importe,idcomprobante,saldo,nrodoc)
                      VALUES(51,rfactventa.barra,rdatoscliente.elidctacte::varchar,now(),
                     concat('Nota Credito ', to_char(elcomprobante.nrosucursal, '0000')
                         , '-' ,  to_char(elcomprobante.nrofactura, '00000000')) ,
                     10311, montocuentacorriente,(elcomprobante.nrofactura*100)+elcomprobante.nrosucursal,
                            montocuentacorriente,rfactventa.nrodoc);

                
                  INSERT INTO ctactepagocliente(idcomprobantetipos,idclientectacte,fechamovimiento,movconcepto,
                    nrocuentac,importe,idcomprobante,saldo)
                      VALUES(51,rdatoscliente.idclientectacte,now(),
                     concat('Nota Credito ', to_char(elcomprobante.nrosucursal, '0000')
                         , '-' ,  to_char(elcomprobante.nrofactura, '00000000')) ,
                     10311, montocuentacorriente,(elcomprobante.nrofactura*100)+elcomprobante.nrosucursal,
                            montocuentacorriente);

                 END IF; 

               END IF; 
     
            END IF; --DE SI ES DEUDA O PAGO EL MOVIMIENTO
         END IF; -- HAY Un tipo movimiento en la tabla
       END IF;--hay un movimiento en la cta cte 

   IF  elcomprobante.tipofactura = 'LI' THEN 
          /* Dejo la LI en estado sincronizado */
         INSERT INTO multivac.facturaventa_migrada(nrofactura, tipocomprobante, nrosucursal,
            tipofactura,centro, iditem, fechamigracion, estaanulada)
            VALUES(elcomprobante.nrofactura, elcomprobante.tipocomprobante, elcomprobante.nrosucursal, elcomprobante.tipofactura, centro(), 0, now(),0 );

   END IF; 
   SELECT INTO  esjubpen * FROM persona WHERE nrodoc=rfactventa.nrodoc AND tipodoc =rfactventa.barra;
              IF (esjubpen.barra=35 or esjubpen.barra=36) THEN

   PERFORM modificaritemfacturajubilados(elcomprobante.tipocomprobante::integer,elcomprobante.nrosucursal::integer,elcomprobante.nrofactura,elcomprobante.tipofactura::varchar
);
              END IF;

    RETURN NEXT elcomprobante;
END;
$function$
