CREATE OR REPLACE FUNCTION public.datosasincronizarconmultivac()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Busca los datos necesarios para sincronizar con Multivac. Los inserta en una tabla temporal.
*/
DECLARE
	cursorminuta CURSOR FOR SELECT * FROM tempminutas;
	regminuta RECORD;
    regprueba RECORD;
    fech_minu date;
    impo double precision;
begin


/*CREATE TEMP TABLE tempminutas (   nroordenpago BIGINT NOT NULL  ) WITHOUT OIDS;
INsERT INTO tempminutas (nroordenpago) VALUES (75675);*/
CREATE TABLE facturaminuta (
             idmultivac BIGINT,
             nroordenpago BIGINT NOT NULL
 ) WITHOUT OIDS;
	

CREATE TABLE imputacionesminuta (
             nroordenpago BIGINT NOT NULL,
             nrocuentac VARCHAR,
             importe DOUBLE PRECISION,
             centrocosto INTEGER
 ) WITHOUT OIDS;


CREATE TABLE debitominuta (
             nroordenpago BIGINT NOT NULL,
             nrocliente VARCHAR,
             barra INTEGER,
             pdescripcion VARCHAR,
             pcuit VARCHAR,
             fechaemision DATE,
             idprestadormultivac INTEGER,
             desccomprobanteventa VARCHAR,
             nrosucursal INTEGER,
             nrofactura BIGINT,
             observacion VARCHAR,
             importeTotal DOUBLE PRECISION,
             importeUnitario DOUBLE PRECISION,
             idconcepto VARCHAR,
             cantidad INTEGER,
             centrocosto INTEGER,
             idcomprobantemultivac BIGINT
 ) WITHOUT OIDS;


CREATE TABLE tempdatossincro(
		          nroordenpago BIGINT NOT NULL,
                   fechaminuta DATE,
                  importe DOUBLE PRECISION
 ) WITHOUT OIDS;


OPEN cursorminuta;
FETCH cursorminuta into regminuta;
WHILE  found LOOP
	--Recupero la fecha del ultimo dia del mes al que corresponde la facturacion
          INSERT INTO tempdatossincro(nroordenpago,fechaminuta)
                                     (SELECT regminuta.nroordenpago, case when nullvalue(max(fechauso)) then max(factura.ffecharecepcion)  - INTEGER '30' else max(fechauso) end
                                      FROM factura NATURAL JOIN tipocomprobante
                                           left join facturaordenesutilizadas using (nroregistro,anio)
                                           left join ordenesutilizadas using(nroorden,centro)
                                      WHERE nroordenpago*100+idcentroordenpago = regminuta.nroordenpago and auditable

                                      );
          UPDATE tempdatossincro set importe=
           (SELECT sum(fimportetotal) as importeTotal
                       FROM factura NATURAL JOIN tipocomprobante WHERE nroordenpago*100+idcentroordenpago = regminuta.nroordenpago and idtipocomprobante<>3 and auditable


                                      )
           WHERE nroordenpago = regminuta.nroordenpago;
/*
Esto es para soportar Minutas que no tienen facturas asociadas
Cristian - Feb/2012
*/
          SELECT fechaminuta into fech_minu
                 from tempdatossincro
                 WHERE nroordenpago = regminuta.nroordenpago;
          if nullvalue(fech_minu) then
             UPDATE tempdatossincro set fechaminuta=
                    (select fechaingreso from ordenpago where nroordenpago*100+idcentroordenpago=regminuta.nroordenpago)
             where nroordenpago = regminuta.nroordenpago;
          end if;
          
          select importe into impo
                 from tempdatossincro
          where nroordenpago = regminuta.nroordenpago;
          if ((impo=0) or nullvalue(impo)) then
             update tempdatossincro set importe =
                    (select importetotal from ordenpago where nroordenpago*100+idcentroordenpago=regminuta.nroordenpago)
             where nroordenpago = regminuta.nroordenpago;
          end if;
/*************************************************************************************************************/
          

    -- select into regprueba * from tempdatossincro;

	--Recupero la facturas y sus idmultivac vinculadas a la minuta
	/*
          INSERT INTO facturaminuta(idmultivac, nroordenpago)
                                     (SELECT factura.idcomprobantemultivac, nroordenpago*100+idcentroordenpago
                                      FROM factura NATURAL JOIN tipocomprobante 
                                      WHERE nroordenpago*100+idcentroordenpago = regminuta.nroordenpago and auditable and idtipocomprobante<>3 
                                      );
    Bloque  Reemplazado el 22-08-2012 por el bloque de abajo - Cristian
    */
          INSERT INTO facturaminuta(idmultivac, nroordenpago)
                                     (SELECT m.idcomprobantemultivac,nroordenpago*100+idcentroordenpago
                                     FROM factura
                                      NATURAL JOIN tipocomprobante
                                      JOIN reclibrofact on factura.nroregistro=reclibrofact.numeroregistro and factura.anio=reclibrofact.anio
                                      --join multivac.mapeocompcompras as m on reclibrofact.idrecepcion=m.idrecepcion and reclibrofact.idcentroregional=m.idcentroregional
join mapeocompcompras as m on reclibrofact.idrecepcion=m.idrecepcion and reclibrofact.idcentroregional=m.idcentroregional
                                     WHERE factura.nroordenpago*100+idcentroordenpago = regminuta.nroordenpago and tipocomprobante.auditable and factura.idtipocomprobante<>3
                                      );

      --select into regprueba * from facturaminuta;


	--Todas las Cuentas involucradas con la Minuta. No tener en Cuenta los Débitos, por defecto seteo valor  centrocosto=1
          INSERT INTO imputacionesminuta(nroordenpago,nrocuentac, importe, centrocosto) 	
                                        (SELECT regminuta.nroordenpago,codigo,debe,1
                                	  FROM ordenpago natural join ordenpagoimputacion
                                	  WHERE nroordenpago*100+idcentroordenpago=regminuta.nroordenpago and debe > 0
                                	  GROUP BY codigo,debe);


      --select into regprueba * from imputacionesminuta;
	--representa todos los debitos
         INSERT INTO debitominuta(nroordenpago,nrocliente,barra,pdescripcion,pcuit,fechaemision,idprestadormultivac,desccomprobanteventa,nrofactura,nrosucursal,importeTotal,idconcepto,cantidad,importeUnitario,centrocosto,idcomprobantemultivac) 	

SELECT regminuta.nroordenpago, TT.nrocliente, TT.barra, TT.pdescripcion, TT.pcuit
		,TT.fechaemision,TT.idprestadormultivac,
		TT.desccomprobanteventa
		,TT.nrofactura, TT.nrosucursal, TT.importeTotal,
		TT.idconcepto,TT.cantidad,TT.importeUnitario, 1 as centrocosto,TT.idcomprobantemultivac

FROM (
SELECT   facturaventa.*,informefacturacion.nrocliente,  prestador.pdescripcion, prestador.pcuit
,mapeoprestadores.idprestadormultivac,	tipocomprobanteventa.desccomprobanteventa
,/*facturaventa.importectacte as importeTotal,*/'40716'::varchar as idconcepto
, 1 as cantidad, /*facturaventa.importectacte*/ debitos.importe as importeunitario, 1 as centrocosto
,idcomprobantemultivac, debitos.importe as importeTotal
from (SELECT * FROM factura
    NATURAL JOIN debitofacturaprestador
    WHERE nroordenpago*100+idcentroordenpago = regminuta.nroordenpago
    ) as debitos
 join informefacturacionnotadebito USING(iddebitofacturaprestador, idcentrodebitofacturaprestador)
 JOIN informefacturacion USING(nroinforme,idcentroinformefacturacion)
 JOIN prestador ON(informefacturacion.nrocliente=prestador.idprestador)
JOIN mapeoprestadores ON(prestador.idprestador= mapeoprestadores.idprestadorsiges)

JOIN informefacturacionestado USING(nroinforme,idcentroinformefacturacion)
 JOIN (SELECT * FROM facturaventa WHERE nullvalue(facturaventa.anulada) ) as facturaventa ON informefacturacion.nrofactura = facturaventa.nrofactura AND informefacturacion.nrosucursal = facturaventa.nrosucursal AND informefacturacion.tipofactura = facturaventa.tipofactura AND informefacturacion.tipocomprobante = facturaventa.tipocomprobante
 JOIN tipocomprobanteventa ON(facturaventa.tipocomprobante=tipocomprobanteventa.idtipo)
WHERE nroordenpago*100+idcentroordenpago = regminuta.nroordenpago AND not nullvalue(facturaventa.nrofactura) AND nullvalue(fechafin) AND idinformefacturacionestadotipo = 4
) AS TT;

      select into regprueba * from debitominuta;

FETCH cursorminuta into regminuta;
END LOOP;
CLOSE cursorminuta;
return true;
end;
$function$
