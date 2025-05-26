CREATE OR REPLACE FUNCTION public.far_arreglardescuentos()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
     --REGISTROS
     ritemfacturaventa record;
     rfacturaventa record;
     rlosimportesiva record;
     citemfacturaventa refcursor;

     cfacturaventa refcursor;
     closimportesiva refcursor;
     importedescuento double precision;
     sumaconiva double precision;
     sumaexento double precision;
     elporcentaje  double precision;
     importetotal double precision;
     impcalculado double precision;
     diferencia double precision;
     eliditem bigint;
          
BEGIN
     importedescuento = 0;
     importetotal = 0;
     sumaconiva = 0;
     sumaexento = 0;
     elporcentaje =0;
     impcalculado = 0 ;
     OPEN cfacturaventa  FOR
               SELECT *
               FROM facturaventa
               WHERE -- nrofactura= 144238 AND
                     ---and nrosucursal = 2 and
                fechaemision>='2014-01-01' AND fechaemision<='2014-01-31'
               and tipofactura='FA' and tipocomprobante =1 and nrosucursal = 2 ;

      FETCH cfacturaventa into rfacturaventa;
      WHILE  found LOOP
                  --- Recupero el importe del descuento
                
                   SELECT INTO importedescuento abs(SUM(importe))
                   FROM itemfacturaventa
                   WHERE nrofactura=rfacturaventa.nrofactura
                         and nrosucursal =rfacturaventa.nrosucursal
                         and tipocomprobante =rfacturaventa.tipocomprobante
                         and tipofactura=rfacturaventa.tipofactura
                         and idconcepto = 50840;
                   IF ( NOT nullvalue(importedescuento) and importedescuento>0 )THEN
                   
                          -- Recupero el importe total de la factura
                          SELECT INTO importetotal sum(importe + (porcentaje * importe)) as impfinal
                          FROM itemfacturaventa JOIN tipoiva using (idiva)
                          WHERE nrofactura=rfacturaventa.nrofactura  and nrosucursal =rfacturaventa.nrosucursal and tipocomprobante =rfacturaventa.tipocomprobante and tipofactura=rfacturaventa.tipofactura
                          and idconcepto <> 50840;
                          IF NOT nullvalue(importetotal) and importetotal>0 THEN
                                 elporcentaje = importedescuento /importetotal;
                                 OPEN closimportesiva  FOR
                                        SELECT SUM(importe +(importe * porcentaje))  as impfinal , idiva ,
                                                                  (elporcentaje * SUM( importe +(importe * porcentaje) )  )as imdescuento
                                                                  ,CASE WHEN (idiva = 1 ) THEN 'Descuentos IVA EXENTO'
                                                                        WHEN (idiva = 2 ) THEN 'Descuento IVA 21%'
                                                                    END as descripciondesc
                                        FROM itemfacturaventa
                                        JOIN tipoiva using  (idiva)
                                        WHERE nrofactura=rfacturaventa.nrofactura  and nrosucursal =rfacturaventa.nrosucursal
                                              and tipocomprobante =rfacturaventa.tipocomprobante and tipofactura=rfacturaventa.tipofactura
                                              and idconcepto <> 50840
                                        group by idiva;
                                 impcalculado = 0;
                                 FETCH closimportesiva into rlosimportesiva;
                                 WHILE  found LOOP
                                 -- INSERTO LOS NUEVOS ITEM DE DESCUENTOS
                                     impcalculado =impcalculado + round(CAST ((rlosimportesiva.imdescuento ) AS numeric),2);
                                     INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,
                                         idconcepto,cantidad,importe,descripcion,idiva)
                                      VALUES(rfacturaventa.tipocomprobante,rfacturaventa.nrosucursal,rfacturaventa.tipofactura,rfacturaventa.nrofactura ,
                                         50840999,1,round(CAST ((rlosimportesiva.imdescuento ) AS numeric),2)*-1,rlosimportesiva.descripciondesc,rlosimportesiva.idiva);
                                         eliditem = currval('itemfacturaventa_iditem_seq');
                                 FETCH closimportesiva into rlosimportesiva;
                                 END LOOP;
                                 close closimportesiva;
                                -- diferencia = round(CAST(10.23 AS numeric)   ,2) ;
                                 diferencia = round(CAST(abs(impcalculado) - abs(importedescuento) AS numeric ) ,2) ;
                                 IF abs(diferencia) <=0.01 THEN
                                          UPDATE itemfacturaventa
                                          SET importe = importe + diferencia
                                          WHERE nrofactura=rfacturaventa.nrofactura  and nrosucursal =rfacturaventa.nrosucursal
                                                and tipocomprobante =rfacturaventa.tipocomprobante and tipofactura=rfacturaventa.tipofactura
                                                and iditem = eliditem  ;
                                                
                                 END IF;

                                 

                          END IF;

                   END IF;

       FETCH cfacturaventa into rfacturaventa;
      END LOOP;
      close cfacturaventa;
   

return 12;
END;
$function$
