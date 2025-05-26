CREATE OR REPLACE FUNCTION public.anularfacturaventa(integer, integer, character varying, bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
elem RECORD;
rplanpago RECORD;
resp BOOLEAN;

--cursor que tiene los datos si la factura venta a anular corresponde a una orden, no debe entrar aca si es una orden reintegro
anularfacvta CURSOR FOR SELECT *
            FROM facturaorden
            JOIN orden USING (nroorden,centro)
			JOIN facturaventa USING (nrosucursal,nrofactura,tipofactura,tipocomprobante)
  			LEFT JOIN informefacturacion USING (nrosucursal,nrofactura,tipofactura,tipocomprobante)
                        LEFT JOIN informefacturacionexpendioreintegro AS ifer USING (nroinforme,idcentroinformefacturacion )
			WHERE nrosucursal=$1 AND nrofactura=$4 AND tipofactura=$3 AND tipocomprobante=$2
--KR 17-09-19 las ordenes facturadas en cta cte generan informes, se cambia la restricción para que se encuentren.
--KR 13-07-21 AGrego tipo info 14 ya que ahora todos los comprobantes que se pagan en cta cte tienen asociado un informe generico
                         AND (idinformefacturaciontipo= 11  or idinformefacturaciontipo= 14 or nullvalue(nroinforme))
			/*AND nullvalue(informefacturacion.nrofactura) AND nullvalue(informefacturacion.tipofactura) 
			AND nullvalue(informefacturacion.nrosucursal) AND nullvalue(informefacturacion.tipocomprobante)
                        AND nullvalue(ifer.nroinforme)*/;

reganularfacvta RECORD;



--cursor que tiene los datos si la factura venta a anular corresponde a un informe
/*KR 20-09-21 puse distinct pq invocaba al sp que anula y por ende si corresponde genera mto en cta cte tantas veces como ordenes tenga la factura, aunque la realidad es que aqui dado el comentario de ML 13-08-2021 ya no seria necesario el LEFT JOIN facturaorden pero lo dejo por si en el futuro algo cambia */

anularfacinfo CURSOR FOR SELECT DISTINCT nroinforme,idcentroinformefacturacion,idinformefacturaciontipo FROM facturaventa
           JOIN informefacturacion USING (nrosucursal,nrofactura,tipofactura,tipocomprobante) LEFT JOIN facturaorden USING(nrosucursal,nrofactura,tipofactura,tipocomprobante)
           WHERE nrosucursal=$1 AND nrofactura=$4 AND tipofactura=$3 AND tipocomprobante=$2  
           -- MaLaPi 13-08-2021 Lo comento, pues desde el 13-07-2021 todos los movimientos que generan ctacte usan informe, incluso cuandos se emite una orden
           --AND nullvalue(facturaorden.nroorden)
           ;
reganularfacinfo RECORD;

                        
anularfacfarmacia CURSOR FOR  SELECT *
                   FROM facturaventa
                   NATURAL JOIN facturaorden
                   JOIN far_ordenventa ON (nroorden=idordenventa and facturaorden.centro =idcentroordenventa )
                   WHERE nrosucursal=$1 AND nrofactura=$4 AND tipofactura=$3 AND tipocomprobante=$2 ;

reganularfacfarmacia RECORD;
BEGIN


OPEN anularfacvta;
FETCH anularfacvta into reganularfacvta;
 WHILE FOUND LOOP
   		SELECT INTO resp * FROM  facturarexpendioordeninterno(reganularfacvta.nroorden,reganularfacvta.centro);
    FETCH anularfacvta INTO reganularfacvta;
 END LOOP;
CLOSE anularfacvta;

-- Creo la tabla para guardar los items del informe de facturacion
 IF iftableexists('ttinformefacturacionitem') THEN
     delete from ttinformefacturacionitem;
 else 
      CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR,idiva INTEGER);
   
 end if;
    
open anularfacinfo;
fetch anularfacinfo into reganularfacinfo;
 WHILE FOUND LOOP
   
           SELECT INTO resp * FROM   anularfacturaventainforme(reganularfacinfo.nroinforme,reganularfacinfo.idcentroinformefacturacion,reganularfacinfo.idinformefacturaciontipo);

     DELETE FROM  ttinformefacturacionitem; 
 fetch anularfacinfo into reganularfacinfo;
 END LOOP;
close anularfacinfo;

--- Anular las ordenes de venta de farmacia vinculadas al comprobante
open anularfacfarmacia;
fetch anularfacfarmacia into reganularfacfarmacia;
      IF FOUND THEN     
           WHILE FOUND LOOP
                SELECT INTO resp *
                FROM  far_cambiarestadoordenventa(reganularfacfarmacia.idordenventa,reganularfacfarmacia.idcentroordenventa,1);
                           
           fetch anularfacfarmacia into reganularfacfarmacia;
           END LOOP;

      END IF;
close anularfacfarmacia;


-- KR se pone en produccion el 03-01-19
-- KR LO PONGO EN PRODUCCION 10-12-19
--- Anular si existen para la factura, los planes de pago
SELECT INTO rplanpago *  FROM facturaventa NATURAL JOIN cuentacorrientedeudafacturaventa 
                          WHERE nrosucursal=$1 AND nrofactura=$4 AND tipofactura=$3 AND tipocomprobante=$2 ;
IF FOUND THEN 
      SELECT INTO resp * FROM anularplanpagocompfacturacion($1,$2,$3,$4);
END IF; 

return resp;
END;
$function$
