CREATE OR REPLACE FUNCTION public.arreglarfacturas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	facturas CURSOR FOR SELECT nrofactura,tipofactura,tipocomprobante,nrosucursal,
    importeefectivo, importedebito,importectacte,importecredito,importe
    FROM facturaventa join
    (SELECT nrofactura,nrosucursal,tipocomprobante,tipofactura,SUM(importe) AS importe
    FROM itemfacturaventa
    group by nrofactura,nrosucursal,tipocomprobante,tipofactura
    ) as importeDeItems USING (nrofactura,nrosucursal,tipocomprobante,tipofactura)
    WHERE importedebito <> importe
    AND importeefectivo <> importe
    AND importectacte <> importe
    AND fechaemision >= '2008/12/01'
    ORDER BY nrofactura;
    
	resultado boolean;
	fact RECORD;
	nrofact bigint;
	tipofact varchar;
	formapago bigint;
	nrosuc integer;
	tipocomp integer;
	importefinal double precision;
	amuc double precision;
	sosunc double precision;

BEGIN
     resultado = true;
     OPEN facturas;
     FETCH facturas INTO fact;
     
     WHILE found LOOP

            nrofact = fact.nrofactura;
            tipofact = fact.tipofactura;
            nrosuc = fact.nrosucursal;
            tipocomp = fact.tipocomprobante;
            importefinal = fact.importe;
            
            SELECT INTO formapago
            DISTINCT idformapagotipos
            FROM facturaorden
            NATURAL JOIN orden
            NATURAL JOIN importesorden
            WHERE nrofactura = nrofact
            AND tipofactura = tipofact
            AND nrosucursal  = nrosuc
            AND tipocomprobante = tipocomp
            AND idformapagotipos <> 6
            AND idformapagotipos <> 1;
            
            SELECT INTO amuc SUM(importe)
            FROM facturaorden
            NATURAL JOIN orden
            NATURAL JOIN importesorden
            WHERE nrofactura = nrofact
            AND tipofactura = tipofact
            AND nrosucursal  = nrosuc
            AND tipocomprobante = tipocomp
            AND idformapagotipos = 1;
            
            SELECT INTO sosunc SUM(importe)
            FROM facturaorden
            NATURAL JOIN orden
            NATURAL JOIN importesorden
            WHERE nrofactura = nrofact
            AND tipofactura = tipofact
            AND nrosucursal  = nrosuc
            AND tipocomprobante = tipocomp
            AND idformapagotipos = 6;
            
            IF (formapago = 2) THEN
               UPDATE facturaventa SET importeefectivo = importefinal,
               importedebito = 0, importecredito = 0,importectacte = 0,
               importesosunc = sosunc, importeamuc = amuc
               WHERE nrofactura = nrofact AND tipofactura = tipofact
               AND nrosucursal  = nrosuc  AND tipocomprobante = tipocomp;
            END IF;

            IF (formapago = 3) THEN
               UPDATE facturaventa SET importeefectivo = 0,
               importedebito = 0, importecredito = 0,importectacte = importefinal,
               importesosunc = sosunc, importeamuc = amuc
               WHERE nrofactura = nrofact AND tipofactura = tipofact
               AND nrosucursal  = nrosuc  AND tipocomprobante = tipocomp;
            END IF;
            
            IF (formapago = 4) THEN
               UPDATE facturaventa SET importeefectivo = 0,
               importedebito = importefinal, importecredito = 0,importectacte = 0,
               importesosunc = sosunc, importeamuc = amuc
               WHERE nrofactura = nrofact AND tipofactura = tipofact
               AND nrosucursal  = nrosuc  AND tipocomprobante = tipocomp;
            END IF;
            
            IF (formapago = 5) THEN
               UPDATE facturaventa SET importeefectivo = 0,
               importedebito = 0, importecredito = importefinal,importectacte = 0,
               importesosunc = sosunc, importeamuc = amuc
               WHERE nrofactura = nrofact AND tipofactura = tipofact
               AND nrosucursal  = nrosuc  AND tipocomprobante = tipocomp;
            END IF;
            
            FETCH facturas INTO fact;
     END LOOP;
     CLOSE facturas;
     return resultado;

END;
$function$
