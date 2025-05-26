CREATE OR REPLACE FUNCTION public.far_asentarconsumoctacte(bigint, integer, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
   --VARIABLES
       ptipocomprobante integer;
       pnrosucursal integer;
       pnrofactura bigint;
       ptipofactura varchar ;
       idinformefacturacion INTEGER;
       eltipoinfo INTEGER;  
       montocuentacorriente DOUBLE PRECISION;
       todook VARCHAR;
   --RECORD
      far_compfact RECORD;  
 
BEGIN

     pnrofactura  =$1;
     pnrosucursal =$2;
     ptipocomprobante =$3;
     ptipofactura  =$4;
     SELECT INTO far_compfact * FROM facturaventa NATURAL JOIN facturaventacupon 
                    JOIN tipocomprobanteventa ON(facturaventa.tipocomprobante=tipocomprobanteventa.idtipo)
                 WHERE tipocomprobante = ptipocomprobante AND tipofactura=ptipofactura AND 
                 nrofactura= pnrofactura AND nrosucursal=  pnrosucursal 
--KR 28-03-22 CONtrolo aqui el valor caja
--960 Cta Cte Cliente o 60 Cta.Cte.Farmacia
--KR 27-03-23 agrego tambien las FPs CC-Sosunc Cobranza y CC-Sosunc Cobranza Cliente
           AND (idvalorescaja = 60 OR idvalorescaja = 960 or  idvalorescaja = 750 or  idvalorescaja = 972);
    
   IF FOUND THEN 
     SELECT INTO montocuentacorriente  sum(monto) 
          FROM facturaventacupon NATURAL JOIN valorescaja 
          WHERE   idformapagotipos = 3 AND
                     tipocomprobante = ptipocomprobante AND tipofactura=ptipofactura AND 
                 nrofactura= pnrofactura AND nrosucursal=  pnrosucursal;

     SELECT INTO idinformefacturacion * FROM  crearinformefacturacion(far_compfact.nrodoc,far_compfact.barra,11);

     INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
        (SELECT centro(), idinformefacturacion, idconcepto, cantidad, SUM(importe) as importe,  descripcion
              FROM itemfacturaventa
                WHERE  tipocomprobante = ptipocomprobante AND tipofactura=ptipofactura AND 
                 nrofactura= pnrofactura AND nrosucursal=  pnrosucursal
              GROUP BY centro(), idinformefacturacion,idconcepto,cantidad,descripcion);

      UPDATE informefacturacion  SET

                 
                 nrofactura = pnrofactura ,
                 tipocomprobante = ptipocomprobante ,
                 nrosucursal = pnrosucursal ,
                 tipofactura = ptipofactura,
                 idtipofactura = ptipofactura,
                 idformapagotipos = 3
          WHERE idcentroinformefacturacion = centro() and  nroinforme = idinformefacturacion;

    /*  
      IF (far_compfact.barra < 100) THEN 
              INSERT INTO cuentacorrientedeuda (
                idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,
                nrocuentac,importe,idcomprobante,saldo, idconcepto, nrodoc, idcentrodeuda)VALUES
                (21,far_compfact.barra,concat(far_compfact.nrodoc,far_compfact.barra::varchar), now(),
                concat('Comp. Facturacion: ', ptipofactura,' ', far_compfact.desccomprobanteventa ,' ', to_char(pnrosucursal, '0000')
                ,to_char(pnrofactura, '00000000') ),
                10311,montocuentacorriente, (idinformefacturacion*100)+centro(),
                 montocuentacorriente,387,far_compfact.nrodoc,centro() );
         ELSE 
        	SELECT INTO eltipoinfo dartipoinformecliente(far_compfact.nrodoc,far_compfact.barra,far_compfact.tipofactura);
                IF (eltipoinfo <>11) THEN
			UPDATE informefacturacion SET idinformefacturaciontipo=eltipoinfo
				WHERE nroinforme=idinformefacturacion AND idcentroinformefacturacion=centro();
		END IF;

               PERFORM generardeudaordenesinstitucion(idinformefacturacion); 

                PERFORM  cambiarestadoinformefacturacion(idinformefacturacion,centro(),4,
                              'Generado desde far_asentarconsumoctacte x deuda cliente' );
      END IF;
*/
      /*KR 03-06-20 Modifico la forma en que se genera la deuda para el cliente */
       SELECT INTO todook * FROM sys_generar_movimientoctacte (concat('{movconcepto=null ,nrodoc=' , far_compfact.nrodoc, ',barra =',far_compfact.barra,' , nrofactura= ',pnrofactura,' , tipocomprobante= ',ptipocomprobante,', tipofactura= ', ptipofactura,', nrosucursal= ',pnrosucursal, ', nroinforme=',idinformefacturacion, ', idcentroinformefacturacion= ',centro(),',idcomprobantetipos=',21, ' }'));

 END IF;

return true;
END;
$function$
