CREATE OR REPLACE FUNCTION public.w_asentarcomprobantefacturacioninformes(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD      
runifa RECORD;
elcomprobante RECORD;
rorigenctacte RECORD;
rfiltros record;

--CURSOR
cursorifa REFCURSOR;

--VARIABLES
vusuario BIGINT;
vmovconcepto VARCHAR;
todook VARCHAR; 
elcomprobantefv VARCHAR default '';
BEGIN

vusuario = sys_dar_usuarioactual();

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

CREATE TEMP TABLE tempfacturaventa ( fvfechaemision DATE,tipocomprobante INTEGER , nrosucursal INTEGER , nrofactura BIGINT , nrodoc VARCHAR, tipodoc SMALLINT, ctacontable INTEGER, centro INTEGER , tipofactura VARCHAR, barra BIGINT ,importedescuento DOUBLE PRECISION , idinformefacturaciontipo INTEGER , idusuario BIGINT ,ctacte boolean , fvgeneramvtoctacte BOOLEAN);
CREATE TEMP TABLE tempfacturaventacupon ( idvalorescaja INTEGER ,  autorizacion VARCHAR ,  nrotarjeta VARCHAR,  monto DOUBLE PRECISION ,  montodto DOUBLE PRECISION ,  cuotas SMALLINT ,  fvcporcentajedto DOUBLE PRECISION ,  nrocupon VARCHAR);
CREATE TEMP TABLE temitemfacturaventa ( idconcepto  VARCHAR , cantidad INTEGER , importe DOUBLE PRECISION , subtotal DOUBLE PRECISION , ivaimporte DOUBLE PRECISION , descripcion VARCHAR, idinformefacturaciontipo INTEGER, idiva INTEGER,iditemcc INTEGER );
CREATE TEMP TABLE tempcentrocostos ( importe DOUBLE PRECISION ,idcentrocosto integer NOT NULL,iditemcc INTEGER ) WITHOUT OIDS;
CREATE TEMP TABLE tempinforme ( nroinforme INTEGER ,idcentroinformefacturacion INTEGER) WITHOUT OIDS;

/* KR 23-06-21 viene de java el pendiente
 OPEN cursorifa FOR SELECT nroinforme, idcentroinformefacturacion,idinformefacturaciontipo,idaporte,idcentroregionaluso,idtipofactura,nrocliente as nrodoc,barra, mes, ano 
                FROM informefacturacion NATURAL JOIN informefacturacionaporte NATURAL JOIN aporte
               NATURAL JOIN informefacturacionestado
               WHERE idinformefacturacionestadotipo = 3 AND nullvalue(fechafin) ;
            --   LIMIT 100;
 FETCH cursorifa INTO runifa;
 WHILE FOUND LOOP
 RAISE NOTICE 'Vamos con (%)',runifa;
 */      
  SELECT INTO runifa nroinforme, idcentroinformefacturacion,idinformefacturaciontipo,idaporte,idcentroregionaluso,idtipofactura,nrocliente as nrodoc,barra, mes, ano 
  FROM informefacturacion NATURAL JOIN informefacturacionaporte NATURAL JOIN aporte
  WHERE nroinforme=rfiltros.nroinforme AND idcentroinformefacturacion= rfiltros.idcentroinformefacturacion;
  IF FOUND THEN 
     
      INSERT INTO tempinforme(nroinforme, idcentroinformefacturacion) VALUES(runifa.nroinforme,runifa.idcentroinformefacturacion);

      INSERT INTO tempfacturaventa (fvfechaemision,tipocomprobante, nrosucursal,nrofactura,nrodoc,tipofactura,barra,idusuario,ctacte,fvgeneramvtoctacte)

      SELECT case when nullvalue(rfiltros.fechaemision) and date_part('day', current_date) > 15 then  date_trunc('month',current_date+20)::date else rfiltros.fechaemision end as fechaemision,t.tipocomprobante, t.nrosucursal, t.sgtenumero,trim(nrocliente), t.tipofactura, cliente.barra, vusuario, true,false
FROM informefacturacion NATURAL JOIN cliente NATURAL JOIN relacionclientecomprobanteventa  NATURAL JOIN tipocomprobanteventa JOIN talonario t ON  (tipocomprobanteventa.idtipo =  t.tipocomprobante AND t.centro=centro() and informefacturacion.idtipofactura= t.tipofactura)  
     
        WHERE  timprime AND centro = centro() AND nroinforme=runifa.nroinforme AND idcentroinformefacturacion= runifa.idcentroinformefacturacion AND t.nrosucursal=rfiltros.nrosucursal;  
         
      INSERT INTO temitemfacturaventa(idconcepto,cantidad,importe,descripcion,idiva)
      SELECT nrocuentac, 1, sum(importe),concat(nrocuentac ,' - ', ifi.descripcion),idiva
      FROM informefacturacionitem ifi  
      WHERE nroinforme=runifa.nroinforme AND idcentroinformefacturacion= runifa.idcentroinformefacturacion
      GROUP by nrocuentac,ifi.descripcion,nroinforme, idcentroinformefacturacion,idiva;  

      --KR 02-03-23 Cuando el tipo de factura es NC la FP para adherentes es la 972. TKT 5588
      INSERT INTO tempfacturaventacupon (idvalorescaja  ,autorizacion,nrotarjeta ,monto ,cuotas,nrocupon,fvcporcentajedto,montodto)  
      SELECT case when runifa.idtipofactura='NC'THEN 972 else 960 end, '0','0', sum(importe),'1','0','0.0','0.00'
      FROM informefacturacionitem ifi
      WHERE nroinforme=runifa.nroinforme AND idcentroinformefacturacion= runifa.idcentroinformefacturacion;

      SELECT INTO elcomprobante * FROM asentarcomprobantefacturacioninformes() as (nrofactura bigint, tipocomprobante integer, nrosucursal integer, tipofactura varchar, seimprime boolean);

      INSERT INTO facturaventa_wsafip( tipocomprobante, nrosucursal, nrofactura, tipofactura, fvafechacreacion,idaporte,idcentroregionaluso)
    VALUES (elcomprobante.tipocomprobante,elcomprobante.nrosucursal,elcomprobante.nrofactura,elcomprobante.tipofactura, now(),runifa.idaporte, runifa.idcentroregionaluso);
   
     SELECT INTO todook * FROM sys_generar_movimientoctacte (concat('{nrodoc=' , runifa.nrodoc, ',modificarconcepto=','no',',barra =',runifa.barra,' , nrofactura= ',elcomprobante.nrofactura,' , tipocomprobante= ',elcomprobante.tipocomprobante,', tipofactura= ',
     elcomprobante.tipofactura,', nrosucursal= ',elcomprobante.nrosucursal, ', nroinforme=',runifa.nroinforme, ', idcentroinformefacturacion= ',runifa.idcentroinformefacturacion,',idcomprobantetipos=21',', movconcepto = ', concat('Pago aporte ', runifa.mes, '- ', runifa.ano),  '}'));

      elcomprobantefv = concat (elcomprobante.nrofactura,'-', elcomprobante.tipocomprobante,'-', elcomprobante.tipofactura,'-', elcomprobante.nrosucursal);
      DROP TABLE tempfacturaventa;
      DROP TABLE temitemfacturaventa;
      DROP TABLE tempfacturaventacupon;
      DROP TABLE tempinforme;
      DROP TABLE tempcentrocostos ;
/* FETCH cursorifa INTO runifa;

 END LOOP;
 CLOSE cursorifa;*/ 
 ELSE 
   RAISE EXCEPTION 'No Existe el Nro. de informe que desea facturar % % ',rfiltros.nroinforme,rfiltros.idcentroinformefacturacion;
	         
 END IF;
return elcomprobantefv ;
END;$function$
