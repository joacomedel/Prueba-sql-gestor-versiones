CREATE OR REPLACE FUNCTION public.far_arreglardescuentos2()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
     --REGISTROS
     ritemfacturaventa record;
     rfacturaventa record;
     rlosimportesiva record;
     citemfacturaventa refcursor;
     
     undescuento record;
      cfar_ordenventaimporte refcursor;
     cfacturaventa refcursor;
     closimportesiva refcursor;
     importedescuento double precision;
     sumaconiva double precision;
     sumaexento double precision;
     elporcentaje  double precision;
     importetotal double precision;
     importepagado double precision;
     impcalculado double precision;
     importetotalfacturado double precision;
     importesindescuento double precision;
     diferencia double precision;
     eliditem bigint;
     pagodescuento double precision;
     elimportedescuento  double precision;

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
              WHERE  nrosucursal = 16 and nrofactura=3763
               and tipofactura='FA' and tipocomprobante =1;

      FETCH cfacturaventa into rfacturaventa;
      WHILE  found LOOP

 --- Malapi 20-01-2015 Recupero el importe total de la factura

SELECT INTO importetotal SUM(importe +(importe * porcentaje))  as impfinal 
FROM itemfacturaventa
JOIN tipoiva using  (idiva)
                          WHERE nrofactura=rfacturaventa.nrofactura
                         and nrosucursal =rfacturaventa.nrosucursal
                         and tipocomprobante =rfacturaventa.tipocomprobante
                         and tipofactura=rfacturaventa.tipofactura
                         and idconcepto <> 50840;

 --- Malapi 20-01-2015 Recupero el importe pagado

SELECT INTO importepagado abs(SUM(monto)) as imppagado
                   FROM facturaventacupon
                  WHERE nrofactura=rfacturaventa.nrofactura
                         and nrosucursal =rfacturaventa.nrosucursal
                         and tipocomprobante =rfacturaventa.tipocomprobante
                         and tipofactura=rfacturaventa.tipofactura;
                 
                  --- Recupero el importe del descuento


                   SELECT INTO importedescuento (importetotal - importepagado);
                   importetotal = 0;

                              
                   IF ( NOT nullvalue(importedescuento) and importedescuento>0 )THEN
                       --- Recupero el importe sin descuento
                       SELECT  INTO importesindescuento SUM(far_ordenventaitemimportes.oviimonto ) as importetotalafil
                       FROM far_ordenventaitemimportes
                       NATURAL JOIN far_ordenventaitem
                       JOIN tipoiva ON(idiva=oviidiva)
                       JOIN facturaorden ON (idordenventa = nroorden and idcentroordenventa=centro)
                       WHERE  idvalorescaja = 0
                           and nrofactura=rfacturaventa.nrofactura and nrosucursal =rfacturaventa.nrosucursal
                           and tipocomprobante =rfacturaventa.tipocomprobante and tipofactura=rfacturaventa.tipofactura;



                        ----- Aca se calcula el importe pagado por el afiliado teniendo en cuenta los descuentos * cada forma de pago
                        SELECT INTO  pagodescuento SUM( monto )
                        FROM facturaventacupon
                        JOIN valorescaja USING (idvalorescaja)
                        WHERE ((idformapagotipos <> 3) or(idvalorescaja =3 or idvalorescaja =64 or idvalorescaja =11 or idvalorescaja =10))
                              and nrofactura=rfacturaventa.nrofactura and nrosucursal =rfacturaventa.nrosucursal
                              and tipocomprobante =rfacturaventa.tipocomprobante and tipofactura=rfacturaventa.tipofactura;


                        ----- Aca se calcula el importe TOTAL que paga el afiliado agrupado por tipo de iva
                        OPEN cfar_ordenventaimporte FOR
                             SELECT SUM(far_ordenventaitemimportes.oviimonto ) as importetotalafil,oviidiva,
                             concat('Desc. IVA ',descripcion) as descripciondescuento
                             FROM far_ordenventaitemimportes
                             NATURAL JOIN far_ordenventaitem
                             JOIN tipoiva ON(idiva=oviidiva)
                             JOIN facturaorden ON (idordenventa = nroorden and idcentroordenventa=centro)
                             WHERE  idvalorescaja = 0
                                    and nrofactura=rfacturaventa.nrofactura and nrosucursal =rfacturaventa.nrosucursal
                                    and tipocomprobante =rfacturaventa.tipocomprobante and tipofactura=rfacturaventa.tipofactura
                             group by oviidiva,descripcion;

                      --- Se debe insertar en item facturaventa el importe del descuelto
                      impcalculado =0;
                      elporcentaje =pagodescuento / importesindescuento; 

                       --- Malapi 20-01-2015 Guardo el % de descuento en Facturaventacupon
                           UPDATE facturaventacupon SET fvcporcentajedto = elporcentaje 
                           WHERE nrofactura=rfacturaventa.nrofactura and nrosucursal =rfacturaventa.nrosucursal
                              and tipocomprobante =rfacturaventa.tipocomprobante and tipofactura=rfacturaventa.tipofactura AND 
                              (idvalorescaja) IN (select idvalorescaja
 from valorescaja where (idformapagotipos <> 3)  or(idvalorescaja =3 or idvalorescaja =64 or idvalorescaja =11 or idvalorescaja =10));
 
                      FETCH cfar_ordenventaimporte into undescuento ;
                      WHILE FOUND LOOP
                            elimportedescuento = ( undescuento.importetotalafil - (elporcentaje * undescuento.importetotalafil) );
                            impcalculado = impcalculado + elimportedescuento;
                            elimportedescuento = round( CAST ( elimportedescuento AS numeric) ,2 ) * -1;
                            INSERT INTO itemfacturaventa(tipocomprobante,nrosucursal,tipofactura,nrofactura,idconcepto,cantidad,importe,descripcion,idiva)
                            VALUES(rfacturaventa.tipocomprobante,rfacturaventa.nrosucursal,rfacturaventa.tipofactura,rfacturaventa.nrofactura,
                                   50840,1,
                                   elimportedescuento,
                                   undescuento.descripciondescuento
                                   ,undescuento.oviidiva);
                            eliditem = currval('itemfacturaventa_iditem_seq');
                            
                            FETCH cfar_ordenventaimporte into undescuento ;
                      END LOOP;
                      close cfar_ordenventaimporte;
                      diferencia = round(CAST(abs(impcalculado) - abs(importedescuento) AS numeric ) ,2) ;
                      IF abs(diferencia) <=0.01 THEN
                                  UPDATE itemfacturaventa
                                  SET importe = importe + diferencia
                                  WHERE nrofactura=rfacturaventa.nrofactura  and nrosucursal =rfacturaventa.nrosucursal
                                                and tipocomprobante =rfacturaventa.tipocomprobante and tipofactura=rfacturaventa.tipofactura
                                                and iditem = eliditem  ;

                      END IF;



              END IF;

                  
       FETCH cfacturaventa into rfacturaventa;
      END LOOP;
      close cfacturaventa;


return 12;
END;
$function$
