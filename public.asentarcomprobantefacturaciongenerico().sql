CREATE OR REPLACE FUNCTION public.asentarcomprobantefacturaciongenerico()
 RETURNS SETOF record
 LANGUAGE plpgsql
AS $function$
DECLARE

--VARIABLES    
montocuentacorriente Double precision;
idinformefacturacion  integer;

--REGISTROS
rfactventa RECORD;
elcomprobante RECORD;
esjubpen RECORD; 
--CURSORES
cfactventagenerico CURSOR for SELECT * FROM tempfacturaventa;



BEGIN


     SELECT INTO elcomprobante * FROM  asentarcomprobantefacturacion() as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);
     

     OPEN cfactventagenerico;
     FETCH cfactventagenerico INTO rfactventa;

   UPDATE facturaventa  SET fechaemision = rfactventa.fechaemision
         
   WHERE nrofactura = elcomprobante.nrofactura AND tipocomprobante = elcomprobante.tipocomprobante AND 
         nrosucursal = elcomprobante.nrosucursal AND tipofactura = elcomprobante.tipofactura;


     IF (rfactventa.deuda AND elcomprobante.tipofactura='FA' )THEN
          --  1 - creo el informe de facturacion
          -- 2 registro la deuda
 	      -- Creo el informe de facturacion
          SELECT INTO montocuentacorriente  sum(monto)
          FROM facturaventacupon NATURAL JOIN valorescaja 
          WHERE  idformapagotipos = 3 AND   nrofactura = elcomprobante.nrofactura AND 
                 tipocomprobante = elcomprobante.tipocomprobante AND 
                 nrosucursal = elcomprobante.nrosucursal AND
                 tipofactura = elcomprobante.tipofactura;

          SELECT INTO idinformefacturacion * FROM  crearinformefacturacion(rfactventa.nrodoc,rfactventa.barra,11);
          INSERT INTO cuentacorrientedeuda (
                idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,
                nrocuentac,importe,idcomprobante,saldo, idconcepto, nrodoc, idcentrodeuda)VALUES
                (21,rfactventa.barra,concat(rfactventa.nrodoc,rfactventa.barra::varchar), now(),
                concat('Emision ',elcomprobante.tipocomprobante , elcomprobante.nrosucursal::varchar
                ,elcomprobante.nrofactura::varchar),
                10311,montocuentacorriente, (idinformefacturacion*100)+Centro(),montocuentacorriente,387,rfactventa.nrodoc,centro() );




                PERFORM  cambiarestadoinformefacturacion(idinformefacturacion,centro(),4,'Generado desde asentarcomprobantefacturaciongenerico x deuda cliente' );
             



          UPDATE informefacturacion  SET
                 nrofactura = elcomprobante.nrofactura ,
                 tipocomprobante = elcomprobante.tipocomprobante ,
                 nrosucursal = elcomprobante.nrosucursal ,
                 tipofactura = elcomprobante.tipofactura,
                 idtipofactura = elcomprobante.tipofactura,
                 idformapagotipos = 3
          WHERE idcentroinformefacturacion = centro() and  nroinforme = idinformefacturacion;

           

       END IF;

   SELECT INTO  esjubpen * FROM persona WHERE nrodoc=rfactventa.nrodoc AND tipodoc =rfactventa.barra;
              IF (esjubpen.barra=35 or esjubpen.barra=36) THEN

   PERFORM modificaritemfacturajubilados(elcomprobante.tipocomprobante::integer,elcomprobante.nrosucursal::integer,elcomprobante.nrofactura,elcomprobante.tipofactura::varchar
);
              END IF;

    RETURN NEXT elcomprobante;
END;
$function$
