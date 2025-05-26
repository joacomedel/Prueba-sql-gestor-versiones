CREATE OR REPLACE FUNCTION public.generarcomprobantefacturacionanuladoconparam(integer, integer, integer, integer, integer, character varying, timestamp without time zone)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--registros
       resultado  RECORD;
       rfactventa record;
--variables
nrofacturadesde  integer;
nrofacturahasta integer;
nrosucursal integer;
tipocomprobante integer;
tipofactura  character varying;

rusuario record;
datofactura record;

BEGIN
nrofacturadesde=$1;
nrofacturahasta=$2;
nrosucursal=$3;
tipocomprobante=$4;
tipofactura=$5;
 
 

   select into datofactura * from facturaventausuario natural join facturaventa 
  where nrofactura=nrofacturadesde-1 and facturaventa.nrosucursal=$3 and facturaventa.tipofactura=$5 and facturaventa.tipocomprobante=$4;

     

            FOR i IN nrofacturadesde..nrofacturahasta  LOOP
	      
	               /* Se inserta la factura anulada */
                  INSERT INTO facturaventa (tipocomprobante,nrosucursal,nrofactura,tipofactura,fechaemision,fechacreacion,anulada,centro)
		          VALUES(tipocomprobante,nrosucursal,nrofacturadesde,tipofactura,$6,$6,$6,datofactura.centro);
                   INSERT INTO itemfacturaventa (tipocomprobante,nrosucursal,nrofactura,tipofactura,idconcepto,cantidad,importe,descripcion,idiva)
                   VALUES(tipocomprobante,nrosucursal,nrofacturadesde,tipofactura,'40718',1,0,'Factura Anulada GMA TK 6183',1);

                   INSERT INTO facturaventacupon (centro,tipocomprobante,nrosucursal,nrofactura,tipofactura,idvalorescaja,monto,autorizacion,nrotarjeta,cuotas,nrocupon)
                   VALUES(datofactura.centro,tipocomprobante,nrosucursal,nrofacturadesde,tipofactura,505,0,'','',0,'');
             
                   INSERT INTO facturaventausuario (tipocomprobante,nrosucursal, nrofactura, tipofactura, idusuario, nrofacturafiscal )
                   VALUES   (tipocomprobante,nrosucursal,nrofacturadesde,tipofactura,datofactura.idusuario,nrofacturadesde);
                   
                   nrofacturadesde= nrofacturadesde+ 1;
       
              
       END LOOP;

   return true;    

END $function$
