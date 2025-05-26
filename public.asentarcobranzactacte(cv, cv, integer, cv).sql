CREATE OR REPLACE FUNCTION public.asentarcobranzactacte(character varying, character varying, integer, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
Dado un rango de fechas y un centro regional y una/s cuentas contables ( INSTITUCION, ASISTENCIAL, TURISMO) ,
se migrarán todos los pagos que se efectuaron en cta cte según estos parámetros, y que aún no se han migrado a multivac.
Esto generará un informe, informefacturacioncobranza, que es una especializacion de informefacturacion;
el mismo vinculara el informe con los idpagos. Se creara un informe x cliente y por forma de pago, salvo para los afiliados; a estos se les creará un solo informe para el tipo de cliente "consumidor final".
PARAMETROS:
           $1 fecha desde
           $2 fecha hasta
           $3 centro regional
           $4 institucion y/o asistencial y/o turismo y/o descuentounc
*/
DECLARE

--VARIABLES
  
    resultado BOOLEAN;
    idinforme INTEGER;
    nroinfo INTEGER;
--REGISTROS
    uninforme RECORD;
    regpago RECORD;
    elem RECORD;
    reginformeexiste RECORD;

--CURSORES
    informes refcursor;
    cursorpago refcursor;
	
BEGIN
-- Creo una tabla temporal para guardar los numeros de informes que utilizo y luego insertar los items de los mismos
IF NOT  iftableexistsparasp('ttnroinforme') THEN
   CREATE TEMP TABLE ttnroinforme (nroinforme INTEGER,idcentroinformefacturacion INTEGER);
END IF;
-- Creo los item del informe de facturacion, para ello uso la temporal que utiliza el SP que inserta en la tabla informefacturacioitem
 
 -- CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);
 
   
  IF ($4 ILIKE 'cliente') THEN --Es una cobranza a un cliente
          OPEN cursorpago FOR SELECT * FROM (
           SELECT ccp.idpago, ccp.idcentropago,ccd.nrodoc  , ccd.tipodoc as barra
                  , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
                  else temppagorecibo.idvalorescaja
                  end as idformapagocobranza,fecharecibo
           FROM cuentacorrientedeuda AS ccd
           JOIN  informefacturacion ON (ccd.idcomprobante =informefacturacion.nroinforme * 100 +informefacturacion.idcentroinformefacturacion 
                                        AND ccd.idcomprobantetipos=21)
           JOIN cuentacorrientedeudapago using (iddeuda,idcentrodeuda)
           JOIN cuentacorrientepagos as ccp using (idpago,idcentropago)
           JOIN recibo ON(ccp.idcomprobante= recibo.idrecibo AND ccp.idcentropago=recibo.centro)
           JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
           LEFT JOIN (SELECT * FROM recibocupon
                               NATURAL JOIN valorescaja
                     ) as temppagorecibo    ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)
           LEFT JOIN informefacturacioncobranza  USING (idpago,idcentropago)
           WHERE  ccp.tipodoc=600 AND not nullvalue(informefacturacion.nrofactura)  
                 AND nullvalue(informefacturacioncobranza.idpago) AND nullvalue(informefacturacioncobranza.idcentropago)
                 AND recibo.fecharecibo::date >=$1
                 AND recibo.fecharecibo::date <=$2
                 AND (ccp.idcentropago=$3 or $3=0)
           ) AS temptable
           ORDER BY temptable.idformapagocobranza,fecharecibo;
          
          
          
     END IF;
 
 
    IF ($4 ilike 'asistencial') THEN
           OPEN cursorpago FOR SELECT * FROM
           (SELECT  DISTINCT ON (ccp.idpago,idformapagocobranza) idpago, ccp.idcentropago,ccd.nrodoc  , ccd.tipodoc as barra
                  , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
                  else temppagorecibo.idvalorescaja
                  end as idformapagocobranza, fecharecibo
	     FROM recibo NATURAL JOIN importesrecibo  JOIN cuentacorrientepagos as ccp  
		ON(ccp.idcomprobante= recibo.idrecibo AND ccp.idcentropago=recibo.centro)
		NATURAL JOIN cuentacorrientedeudapago JOIN cuentacorrientedeuda as ccd   USING (iddeuda, idcentrodeuda) JOIN
		(
                SELECT facturaorden.nroorden*100+facturaorden.centro as idcomprobante,facturaorden.idcomprobantetipos 
                FROM facturaventa NATURAL JOIN facturaorden 
                UNION
                SELECT  (idfacturareciprocidadinfo *100 + idcentrofacturareciprocidadinfo)as idcomprobante, 31 as idcomprobantetipos
                FROM facturareciprocidadinfo
                ) as facturacion ON(ccd.idcomprobante=facturacion.idcomprobante AND ccd.idcomprobantetipos=facturacion.idcomprobantetipos )

		LEFT JOIN (SELECT * FROM recibocupon   NATURAL JOIN valorescaja
                     ) as temppagorecibo    ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)
		LEFT JOIN reciboautomatico as ra ON(recibo.idrecibo=ra.idrecibo AND recibo.centro=ra.centro)
               LEFT JOIN informefacturacioncobranza  USING (idpago,idcentropago)
		WHERE recibo.fecharecibo::date >=$1 AND recibo.fecharecibo::date <=$2 AND
		recibo.centro=$3 AND /*nullvalue(ra.idrecibo)  AND*/ nullvalue(informefacturacioncobranza.idpago) AND nullvalue(informefacturacioncobranza.idcentropago)
                
		            ) AS temptable
           ORDER BY temptable.idformapagocobranza,fecharecibo;
  
     END IF;

     IF ($4 ilike 'turismo') THEN
           OPEN cursorpago FOR SELECT * FROM
                           (SELECT DISTINCT ON (ccp.idpago,idformapagocobranza) idpago, ccp.idcentropago,ccd.nrodoc  , ccd.tipodoc as barra
                  , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
                  else temppagorecibo.idvalorescaja
                  end as idformapagocobranza,fecharecibo
                  FROM informefacturacion NATURAL JOIN informefacturacionturismo 
                  NATURAL JOIN consumoturismo  NATURAL JOIN  prestamo JOIN prestamocuotas as pc USING(idprestamo,idcentroprestamo)
                  JOIN cuentacorrientedeuda as ccd  ON(ccd.idcomprobante= pc.idprestamocuotas*10+pc.idcentroprestamo AND ccd.idcomprobantetipos=7)
                  JOIN cuentacorrientedeudapago AS c USING (iddeuda, idcentrodeuda)
                  JOIN cuentacorrientepagos AS ccp USING (idpago, idcentropago)
                  JOIN recibo  ON(ccp.idcomprobante= recibo.idrecibo AND ccp.idcentropago=recibo.centro)
                  LEFT JOIN reciboautomatico AS ra ON (recibo.idrecibo=ra.idrecibo AND recibo.centro=ra.centro)
                  JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
                  LEFT JOIN (SELECT * FROM recibocupon NATURAL JOIN valorescaja) as temppagorecibo ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)
                  LEFT JOIN informefacturacioncobranza  USING (idpago,idcentropago)

                  WHERE not nullvalue(informefacturacion.nrofactura)  
                   AND nullvalue(informefacturacioncobranza.idpago) AND nullvalue(informefacturacioncobranza.idcentropago)
                   AND recibo.fecharecibo::date >=$1
                   AND recibo.fecharecibo::date <=$2
                   AND (ccp.idcentropago=$3 or $3=0) 
                   AND nullvalue(ra.centro)) AS temptable
                   ORDER BY temptable.idformapagocobranza,fecharecibo;
                           

     END IF;
  
     IF ($4 ILIKE 'prestamo') THEN -- ES UN PRESTAMO O UN PLAN DE PAGO
        OPEN cursorpago FOR SELECT * FROM
                  (SELECT DISTINCT ON (ccp.idpago,idformapagocobranza) idpago, ccp.idcentropago,ccd.nrodoc  , ccd.tipodoc as barra
                  , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
                  else temppagorecibo.idvalorescaja
                  end as idformapagocobranza,fecharecibo
                  FROM prestamo
                  NATURAL JOIN prestamocuotas as pc
                  JOIN cuentacorrientedeuda AS ccd  ON ( ccd.idcomprobante = pc.idprestamocuotas*10+pc.idcentroprestamo )
                  JOIN cuentacorrientedeudapago AS c USING (iddeuda, idcentrodeuda)
                  JOIN cuentacorrientepagos AS ccp USING (idpago, idcentropago)
                  JOIN recibo  ON(ccp.idcomprobante = recibo.idrecibo AND ccp.idcentropago = recibo.centro)
                  LEFT JOIN reciboautomatico AS ra ON (recibo.idrecibo=ra.idrecibo AND recibo.centro=ra.centro)
                  JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
                  LEFT JOIN (SELECT *
                             FROM recibocupon
                             NATURAL JOIN valorescaja
                             ) as temppagorecibo ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)
                  LEFT JOIN informefacturacioncobranza  USING (idpago,idcentropago)
                  WHERE nullvalue(informefacturacioncobranza.idpago)
                        AND nullvalue(informefacturacioncobranza.idcentropago)
                        AND (ccd.idcomprobantetipos=18 OR ccd.idcomprobantetipos=17)
                        AND recibo.fecharecibo::date >=$1
                        AND recibo.fecharecibo::date <=$2
                        AND (ccp.idcentropago=$3 or $3=0)
                        AND nullvalue(ra.centro)
                  ) AS temptable
        ORDER BY temptable.idformapagocobranza,fecharecibo;
     END IF;
     IF ($4 ILIKE 'institucion') THEN --ES INSTITUCION
          OPEN cursorpago FOR SELECT * FROM
                          (SELECT DISTINCT ON (ctactepagonoafil.idpago,idformapagocobranza) idpago, ctactepagonoafil.idcentropago, cliente.nrocliente as nrodoc, cliente.barra
                           , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
            else temppagorecibo.idvalorescaja
            end as idformapagocobranza,fecharecibo
                           FROM cliente JOIN facturaventa ON(cliente.nrocliente=facturaventa.nrodoc AND cliente.barra=facturaventa.barra)
                           JOIN informefacturacion USING (nrofactura, tipocomprobante, nrosucursal, tipofactura)
                           JOIN ctactedeudanoafil
                           ON(informefacturacion.nroinforme*100+informefacturacion.idcentroinformefacturacion=ctactedeudanoafil.idcomprobante
                           AND (ctactedeudanoafil.idcomprobantetipos = 21 or ctactedeudanoafil.idcomprobantetipos = 0))
                           JOIN ctactedeudapagonoafil USING (iddeuda, idcentrodeuda)
                           JOIN ctactepagonoafil USING (idpago, idcentropago)
                           JOIN recibo ON(ctactepagonoafil.idcomprobante= recibo.idrecibo AND ctactepagonoafil.idcentropago=recibo.centro)
                           JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
 LEFT JOIN reciboautomatico AS ra ON (recibo.idrecibo=ra.idrecibo AND recibo.centro=ra.centro)
                           LEFT JOIN
                           (SELECT * FROM recibocupon NATURAL JOIN valorescaja) as temppagorecibo
                           ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)
                           LEFT JOIN informefacturacioncobranza  USING (idpago,idcentropago)
                         
                              WHERE ((nullvalue(informefacturacioncobranza.idpago) AND nullvalue(informefacturacioncobranza.idcentropago)))
                             -- AND cuentacorrientepagos.idconcepto <> 999 Cristian 30-sep-2013
AND (ctactedeudanoafil.idconcepto = 999 OR ctactedeudanoafil.idconcepto = 998)
                           AND recibo.fecharecibo:: date >=$1 AND
                           recibo.fecharecibo:: date <=$2  AND (nullvalue(ra.idrecibo) AND nullvalue(ra.centro)) 
                           AND (ctactepagonoafil.idcentropago=$3 or $3=0)) AS temptable
                            ORDER BY temptable.idformapagocobranza,fecharecibo;
     END IF;
     IF ($4 ILIKE 'descuentounc') THEN --ES descuento UNC
          OPEN cursorpago FOR SELECT * FROM
                          (SELECT ccp.idpago, ccp.idcentropago,persona.nrodoc, persona.barra
                          , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
                          else temppagorecibo.idvalorescaja
                         end as idformapagocobranza,fecharecibo
                        FROM ctactepagonoafil  as ccp 
                        JOIN persona ON (ccp.nrodoc=persona.nrodoc AND ccp.tipodoc=persona.tipodoc) 
                        JOIN recibo ON(ccp.idcomprobante= recibo.idrecibo AND ccp.idcentropago=recibo.centro)
                        JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
                        JOIN reciboautomatico AS ra ON (recibo.idrecibo=ra.idrecibo AND recibo.centro=ra.centro)
                        LEFT JOIN
                       (SELECT * FROM recibocupon NATURAL JOIN valorescaja) as temppagorecibo 
                        ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo) 
                        LEFT JOIN informefacturacioncobranza  USING (idpago,idcentropago) 
                        WHERE ((nullvalue(informefacturacioncobranza.idpago) AND nullvalue(informefacturacioncobranza.idcentropago)))
                        AND recibo.fecharecibo:: date >=$1 AND recibo.fecharecibo:: date <=$2  and ra.idorigenrecibo=2
                        AND (ccp.idcentropago=$3 or $3=0)) AS temptable
                        ORDER BY temptable.idformapagocobranza,fecharecibo;
     END IF;
     FETCH cursorpago INTO regpago;
    
   WHILE FOUND LOOP

    
           SELECT INTO reginformeexiste nroinforme, idformapagocobranza, informefacturacion.idcentroinformefacturacion
            FROM informefacturacioncobranza NATURAL JOIN informefacturacion NATURAL JOIN informefacturacionestado
            WHERE nullvalue(fechafin) AND idinformefacturacionestadotipo = 1 --AND idformapagocobranza=regpago.idformapagocobranza
           AND   fechadesde = regpago.fecharecibo::date AND fechahasta=regpago.fecharecibo::date;


            IF FOUND  THEN -- Si existe algun informe de dicha obra social
                         idinforme = reginformeexiste.nroinforme;

            ELSE
                         SELECT INTO idinforme *            FROM crearinformefacturacion('6',500,7);
                         SELECT INTO nroinfo nroinforme from ttnroinforme WHERE ttnroinforme.nroinforme= idinforme;
                           IF NOT FOUND THEN-- si el informe no existe en la temporal que cree
                             INSERT INTO ttnroinforme values(idinforme,centro());
                           END IF;
                       

           END IF;


     INSERT INTO informefacturacioncobranza
              (nroinforme,idcentroinformefacturacion,idpago,idcentropago,idformapagocobranza,fechadesde,fechahasta)
     VALUES(idinforme,centro(),regpago.idpago,regpago.idcentropago,regpago.idformapagocobranza,regpago.fecharecibo,regpago.fecharecibo);

  
   

     FETCH cursorpago INTO regpago;
     

    END LOOP;

    CLOSE cursorpago;

   OPEN informes FOR SELECT * FROM ttnroinforme;
   FETCH informes INTO uninforme;
   WHILE FOUND LOOP



       PERFORM agregarinformefacturacioncobranzaitem(uninforme.nroinforme, centro(),$4);
       FETCH informes INTO uninforme;

    END LOOP;

    CLOSE informes;


return true;
END;
$function$
