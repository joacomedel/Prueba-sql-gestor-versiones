CREATE OR REPLACE FUNCTION public.generarconsumoctacte(pparametro character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$ 
DECLARE



--RECORD 
   rfaccupon RECORD;
   rfiltros RECORD;
   rorigen RECORD;

--VARIABLES 
   idinformefacturacion INTEGER;
   elidinformefacturaciontipo INTEGER;
BEGIN
   elidinformefacturaciontipo = 11 ;

   EXECUTE sys_dar_filtros(pparametro) INTO rfiltros;

   /*IF existecolumtemp('tempfacturaventa','idinformefacturaciontipo') THEN 
      SELECT INTO  elidinformefacturaciontipo  idinformefacturaciontipo FROM tempfacturaventa;  
   END IF;
 */
   SELECT INTO rfaccupon sum(monto) as monto FROM /*temp*/facturaventacupon JOIN valorescaja USING(idvalorescaja) JOIN formapagotipos USING(idformapagotipos)    
   WHERE nrofactura = rfiltros.nrofactura AND  tipofactura = rfiltros.tipofactura AND tipocomprobante = rfiltros.tipocomprobante AND  nrosucursal = rfiltros.nrosucursal and valorescaja.idvalorescaja= 3;

   IF FOUND AND NOT nullvalue(rfaccupon.monto) THEN    


      SELECT INTO rorigen fv.fechaemision,anulada,fv.nrodoc, fv.tipodoc,  mccc.nrocuentac,
case when nullvalue(o.tipo) then ov.idordenventatipo else o.tipo end as tipo,
text_concatenar(case when nullvalue(o.nroorden) then ov.idordenventa*100+ov.idcentroordenventa else (o.nroorden * 100 + o.centro) end) as compmvto ,tipofactura,fv.barra,
concat(case when nullvalue(fv.anulada) then 'Emision ' else 'Anulacion ' end,' ', case when not nullvalue(text_concatenar(case when nullvalue(o.nroorden) then ov.idordenventa else o.nroorden end)) then concat('Orden/es ',text_concatenar(case when nullvalue(o.nroorden) then ov.idordenventa*100+ov.idcentroordenventa else (o.nroorden * 100 + o.centro) end),' ', p.apellido, ' ', p.nombres, ' ', p.nrodoc,'-', p.barra, ' ' ,tipofactura, ' ',desccomprobanteventa , ' ', nrosucursal, ' ', nrofactura)  else '' end) as movconcepto,nroconcepto


      FROM facturaventa  fv JOIN tipocomprobanteventa ON (tipocomprobante=idtipo) LEFT JOIN facturaorden fo USING(nrofactura, tipocomprobante, nrosucursal, tipofactura) 
 
   LEFT JOIN orden o ON(fo.nroorden=o.nroorden AND fo.centro=o.centro) 
   LEFT JOIN far_ordenventa ov ON(ov.idordenventa=fo.nroorden AND ov.idcentroordenventa=fo.centro) 
   LEFT JOIN persona p ON(fv.nrodoc=p.nrodoc AND fv.tipodoc=p.tipodoc)
      LEFT JOIN mapeocuentascontablesconcepto mccc ON(CASE WHEN not nullvalue(case when nullvalue(o.nroorden) then ov.idordenventa else o.nroorden end) THEN 387 END =nroconcepto)
      WHERE nrofactura = rfiltros.nrofactura AND  tipofactura = rfiltros.tipofactura AND tipocomprobante = rfiltros.tipocomprobante AND  nrosucursal = rfiltros.nrosucursal
       GROUP BY fv.fechaemision,nrocuentac,tipofactura,fv.barra,anulada,nrocuentac,fv.nrodoc, fv.tipodoc,tipo,ov.idordenventatipo,p.apellido, p.nombres, p.nrodoc,p.barra,nroconcepto,desccomprobanteventa,nrosucursal,nrofactura;

     
             
  /*Creo un informe de facturacion para vincular a la deuda*/
        SELECT INTO idinformefacturacion * FROM crearinformefacturacion(rorigen.nrodoc,rorigen.barra,elidinformefacturaciontipo); 
        
        INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
        (SELECT centro(), idinformefacturacion, idconcepto, cantidad, SUM(importe) as importe,  descripcion
         FROM itemfacturaventa
         WHERE  nrofactura = rfiltros.nrofactura AND 
                         tipocomprobante = rfiltros.tipocomprobante AND 
                         nrosucursal = rfiltros.nrosucursal AND
                         tipofactura = rfiltros.tipofactura
         GROUP BY centro(), idinformefacturacion,idconcepto,cantidad,descripcion
        );
        UPDATE informefacturacion  SET
                      nrofactura = rfiltros.nrofactura ,
                      tipocomprobante = rfiltros.tipocomprobante ,
                      nrosucursal = rfiltros.nrosucursal ,
                      tipofactura = rfiltros.tipofactura,
                      idtipofactura = rfiltros.tipofactura,
                      idformapagotipos = 3
        WHERE idcentroinformefacturacion = centro() and  nroinforme = idinformefacturacion;
 


      IF rorigen.tipofactura='FA' AND nullvalue(rorigen.anulada) THEN

  


        INSERT INTO cuentacorrientedeuda (idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,
                                      nrocuentac,importe,idcomprobante,saldo, idconcepto, nrodoc, idcentrodeuda)VALUES
        (21,rorigen.tipodoc,concat(rorigen.nrodoc,rorigen.tipodoc::varchar), rorigen.fechaemision, rorigen.movconcepto,rorigen.nrocuentac,rfaccupon.monto, ((idinformefacturacion*100)+centro()),rfaccupon.monto,rorigen.nroconcepto,rorigen.nrodoc,centro());

      ELSE 
 
         IF ((rorigen.tipofactura='NC' OR rorigen.tipofactura='OT') AND nullvalue(rorigen.anulada))THEN 

            INSERT INTO cuentacorrientepagos(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,nrodoc,idconcepto)
            VALUES(21,rorigen.tipodoc,concat(rorigen.nrodoc,rorigen.tipodoc::varchar),rorigen.fechaemision,rorigen.movconcepto,rorigen.nrocuentac,rfaccupon.monto,((idinformefacturacion*100)+centro()),rfaccupon.monto,rorigen.nrodoc,rorigen.nroconcepto);

         ELSE 
            IF ((rorigen.tipofactura='NC' OR rorigen.tipofactura='OT') AND NOT nullvalue(rorigen.anulada)) THEN 

                INSERT INTO cuentacorrientedeuda (idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,
                                      nrocuentac,importe,idcomprobante,saldo, idconcepto, nrodoc, idcentrodeuda)VALUES
         (21,rorigen.tipodoc,concat(rorigen.nrodoc,rorigen.tipodoc::varchar), rorigen.fechaemision, rorigen.movconcepto,rorigen.nrocuentac,rfaccupon.monto, ((idinformefacturacion*100)+centro()),rfaccupon.monto,rorigen.nroconcepto,rorigen.nrodoc,centro());

            END IF;

         END IF;
      END IF;

   END IF;
           
 
return pparametro;
 
END;
$function$
