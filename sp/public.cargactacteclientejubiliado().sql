CREATE OR REPLACE FUNCTION public.cargactacteclientejubiliado()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
--RECORD       
runifa RECORD;
elcomprobante RECORD;

--CURSOR 
cursorifa REFCURSOR;

--VARIABLES
vusuario BIGINT;
rorigenctacte RECORD;

vmovconcepto VARCHAR;
BEGIN



vusuario = sys_dar_usuarioactual();



CREATE TEMP TABLE  temporal_tempfacturaventa AS SELECT facturaventa.* , true as ctacte ,informefacturacion.nroinforme, informefacturacion.idcentroinformefacturacion, informefacturacion.idinformefacturaciontipo
                                            FROM facturaventa JOIN informefacturacion USING(nrofactura,tipofactura,nrosucursal,tipocomprobante) 
                                             WHERE fechaemision >=current_date and nrosucursal =1001 and tipofactura='FA' and nrodoc<>'08216252';

OPEN cursorifa FOR SELECT * FROM temporal_tempfacturaventa;
FETCH cursorifa INTO runifa;
WHILE FOUND LOOP
         

         CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
	 INSERT INTO tempcliente(nrocliente,barra) VALUES(runifa.nrodoc,runifa.barra);
	 SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5)::integer as centroclavepersonactacte 
				FROM (
				SELECT verifica_origen_ctacte() as origen 
				) as t;
	  DROP TABLE tempcliente;
           IF (rorigenctacte.origentabla = 'clientectacte') THEN 
	       --MaLaPi En la deuda, siempre el origen es un informe de facturacion de aportes
               UPDATE informefacturacion SET idformapagotipos = 3 WHERE nroinforme = runifa.nroinforme AND idcentroinformefacturacion= runifa.idcentroinformefacturacion;
               vmovconcepto = concat('Generar deuda por Cobro Aportes::Emision de ',runifa.tipofactura ,' ', runifa.nrosucursal::varchar
					,' ',runifa.nrofactura::varchar,' Con el Informe ',runifa.nroinforme,'-',runifa.idcentroinformefacturacion); 
		INSERT INTO ctactedeudacliente (idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto
						,nrocuentac,importe,idcomprobante,saldo,fechavencimiento) 
		VALUES(runifa.idinformefacturaciontipo,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte ,now(),vmovconcepto
						,10826,runifa.importectacte, (runifa.nroinforme*100)+runifa.idcentroinformefacturacion , runifa.importectacte,CURRENT_DATE + 30);
	END IF;

FETCH cursorifa INTO runifa;
END LOOP;
CLOSE cursorifa;
return '';
END;

$function$
