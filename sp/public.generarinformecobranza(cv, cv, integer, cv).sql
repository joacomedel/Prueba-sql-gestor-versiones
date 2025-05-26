CREATE OR REPLACE FUNCTION public.generarinformecobranza(character varying, character varying, integer, character varying)
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
    existeinfoso BOOLEAN;
    resultado BOOLEAN;
    idinforme INTEGER;
    nroinfo INTEGER;
  -- esosreci BOOLEAN;
    idPagoCobranza BIGINT;
    existeInfo BOOLEAN;

--REGISTROS
    uninforme RECORD;
    regpago RECORD;
    elem RECORD;
    reginformeexiste RECORD;

--CURSORES
    informes refcursor;
    cursorExisteInfo refcursor;
    cursorpago refcursor;
	
BEGIN
-- Creo una tabla temporal para guardar los numeros de informes que utilizo y luego insertar los items de los mismos
-- CREATE TEMP TABLE ttnroinforme (nroinforme INTEGER);
-- Creo los item del informe de facturacion, para ello uso la temporal que utiliza el SP que inserta en la tabla informefacturacioitem
 -- CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);
--CREATE TEMP TABLE ttnroinforme (nroinforme INTEGER);
-- CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);

    idPagoCobranza =0;
    existeinfoso = false;
    existeInfo = false;
 --   esosreci = true;
  IF ($4 ILIKE 'cliente') THEN --Es una cobranza a un cliente
          OPEN cursorpago FOR SELECT * FROM (
           SELECT ccp.idpago, ccp.idcentropago,ccd.nrodoc  , ccd.tipodoc as barra
                  , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
                  else temppagorecibo.idvalorescaja
                  end as idformapagocobranza
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
           ORDER BY temptable.idformapagocobranza;
          
          
          
     END IF;
 
 
    IF ($4 ilike 'asistencial') THEN
           OPEN cursorpago FOR SELECT * FROM
           (SELECT DISTINCT ON (ccp.idpago,idformapagocobranza) idpago,
                   ccp.idcentropago,ccd.nrodoc  , ccd.tipodoc as barra
                  , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
                  else temppagorecibo.idvalorescaja
                  end as idformapagocobranza
                FROM (
                SELECT nrodoc,tipodoc,facturaorden.nroorden*100+facturaorden.centro as idcomprobante,facturaorden.idcomprobantetipos as idcomprobantetipos
                FROM facturaventa
                JOIN facturaorden USING(nrosucursal, nrofactura, tipocomprobante, tipofactura)
                UNION
                SELECT nrodoc , tipodoc , (idfacturareciprocidadinfo *100 + idcentrofacturareciprocidadinfo)as idcomprobante, 31 as idcomprobantetipos
                FROM facturareciprocidadinfo
               ) as facturacion JOIN cuentacorrientedeuda as ccd  USING(idcomprobante,  idcomprobantetipos  )
           JOIN cuentacorrientedeudapago  USING (iddeuda, idcentrodeuda)
           JOIN cuentacorrientepagos as ccp USING (idpago, idcentropago)
           JOIN  recibo ON(ccp.idcomprobante= recibo.idrecibo AND ccp.idcentropago=recibo.centro)
           JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
           LEFT JOIN (SELECT * FROM recibocupon
                               NATURAL JOIN valorescaja
                     ) as temppagorecibo    ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)
           LEFT JOIN informefacturacioncobranza  USING (idpago,idcentropago)

           WHERE nullvalue(informefacturacioncobranza.idpago) AND nullvalue(informefacturacioncobranza.idcentropago)
                 AND recibo.fecharecibo::date >=$1
                 AND recibo.fecharecibo::date <=$2
                 AND (ccp.idcentropago=$3 or $3=0)
        --   AND cuentacorrientedeuda.idconcepto = 387 AND ccp.idconcepto <> 999
            ) AS temptable
           ORDER BY temptable.idformapagocobranza;
  
     END IF;

     IF ($4 ilike 'turismo') THEN
           OPEN cursorpago FOR SELECT * FROM
                           (SELECT DISTINCT ON (ccp.idpago,idformapagocobranza) idpago, ccp.idcentropago,ccd.nrodoc  , ccd.tipodoc as barra
                  , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
                  else temppagorecibo.idvalorescaja
                  end as idformapagocobranza
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
                   ORDER BY temptable.idformapagocobranza;
                           

     END IF;
  
     IF ($4 ILIKE 'prestamo') THEN -- ES UN PRESTAMO O UN PLAN DE PAGO
        OPEN cursorpago FOR SELECT * FROM
                  (SELECT DISTINCT ON (ccp.idpago,idformapagocobranza) idpago, ccp.idcentropago,ccd.nrodoc  , ccd.tipodoc as barra
                  , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
                  else temppagorecibo.idvalorescaja
                  end as idformapagocobranza
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
                        AND (ccp.idcentropago=1 or 1=0)
                        AND nullvalue(ra.centro)
                  ) AS temptable
        ORDER BY temptable.idformapagocobranza;
     END IF;
     IF ($4 ILIKE 'institucion') THEN --ES INSTITUCION
          OPEN cursorpago FOR SELECT * FROM
                          (SELECT DISTINCT ON (cuentacorrientepagos.idpago,idformapagocobranza) idpago, cuentacorrientepagos.idcentropago, cliente.nrocliente as nrodoc, cliente.barra
                           , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
            else temppagorecibo.idvalorescaja
            end as idformapagocobranza
                           FROM cliente JOIN facturaventa ON(cliente.nrocliente=facturaventa.nrodoc AND cliente.barra=facturaventa.barra)
                           JOIN informefacturacion USING (nrofactura, tipocomprobante, nrosucursal, tipofactura)
                           JOIN cuentacorrientedeuda
                           ON(informefacturacion.nroinforme*100+informefacturacion.idcentroinformefacturacion=cuentacorrientedeuda.idcomprobante
                           AND (cuentacorrientedeuda.idcomprobantetipos = 21 or cuentacorrientedeuda.idcomprobantetipos = 0))
                           JOIN cuentacorrientedeudapago USING (iddeuda, idcentrodeuda)
                           JOIN cuentacorrientepagos USING (idpago, idcentropago)
                           JOIN recibo ON(cuentacorrientepagos.idcomprobante= recibo.idrecibo AND cuentacorrientepagos.idcentropago=recibo.centro)
                           JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
 LEFT JOIN reciboautomatico AS ra ON (recibo.idrecibo=ra.idrecibo AND recibo.centro=ra.centro)
                           LEFT JOIN
                           (SELECT * FROM recibocupon NATURAL JOIN valorescaja) as temppagorecibo
                           ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)
                           LEFT JOIN informefacturacioncobranza  USING (idpago,idcentropago)
                         
                           WHERE ((nullvalue(informefacturacioncobranza.idpago) AND nullvalue(informefacturacioncobranza.idcentropago)))
                             -- AND cuentacorrientepagos.idconcepto <> 999 Cristian 30-sep-2013
AND (cuentacorrientedeuda.idconcepto = 999 OR cuentacorrientedeuda.idconcepto = 998)
                           AND recibo.fecharecibo:: date >=$1 AND
                           recibo.fecharecibo:: date <=$2  AND (nullvalue(ra.idrecibo) AND nullvalue(ra.centro)) 
                           AND (cuentacorrientepagos.idcentropago=$3 or $3=0)) AS temptable
                            ORDER BY temptable.idformapagocobranza;
     END IF;
     IF ($4 ILIKE 'descuentounc') THEN --ES descuento UNC
          OPEN cursorpago FOR SELECT * FROM
                          (SELECT ccp.idpago, ccp.idcentropago,persona.nrodoc, persona.barra
                          , case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
                          else temppagorecibo.idvalorescaja
                         end as idformapagocobranza
                        FROM cuentacorrientepagos  as ccp 
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
                        ORDER BY temptable.idformapagocobranza;
     END IF;
     FETCH cursorpago INTO regpago;
    idPagoCobranza = regpago.idformapagocobranza;
  
    WHILE FOUND LOOP

     IF regpago.barra > 100 THEN
 --verifico que el nrodoc pertenezca a una obra social y no a un afiliado de reciprocidad (informefacturacionreciprocidad)
            SELECT INTO elem *
            FROM persona
            WHERE nrodoc=regpago.nrodoc::varchar AND barra= regpago.barra;
            IF NOT FOUND THEN  --la cobranza es de una obra social por reciprocidad
       -- Busco si existe algun informe que no este en estado sincronizado de la obra social por reciprocidad
       --        OPEN cursorExisteInfo FOR
            SELECT INTO reginformeexiste nroinforme, idformapagocobranza, informefacturacion.idcentroinformefacturacion
            FROM informefacturacioncobranza
            natural join informefacturacion
            natural join informefacturacionestado
           where nullvalue(fechafin)
                 and idinformefacturacionestadotipo = 1
                 and fechainforme = current_date and nrocliente =regpago.nrodoc and barra =regpago.barra;


            IF FOUND AND NOT existeInfo THEN -- Si existe algun informe de dicha obra social
                         idinforme = reginformeexiste.nroinforme;
                         existeInfo= true;
                 END IF;
            IF NOT existeInfo THEN--si NO existe un informe en dicha obra social
                         SELECT INTO idinforme *
                         FROM crearinformefacturacion(regpago.nrodoc,regpago.barra,7);
                         idPagoCobranza =regpago.idformapagocobranza;
              END IF;
       END IF;
      ELSE --Corresponde a un afiliado de Sosunc, se crea un informe de cobranza a los "afiliados"
          -- esosreci = true;
          IF NOT existeinfoso THEN
                    SELECT INTO idinforme * FROM crearinformefacturacion(6::varchar,500::bigint,7);
                    existeinfoso = true;
         
          END IF;
      END IF;
      
     INSERT INTO informefacturacioncobranza
              (nroinforme,idcentroinformefacturacion,idpago,idcentropago,idformapagocobranza,fechadesde,fechahasta)
     VALUES(idinforme,centro(),regpago.idpago,regpago.idcentropago,regpago.idformapagocobranza,$1::date,$2::date);
   
     SELECT INTO nroinfo nroinforme from ttnroinforme WHERE ttnroinforme.nroinforme= idinforme;
     IF NOT FOUND THEN-- si el informe no existe en la temporal que cree
                INSERT INTO ttnroinforme values(idinforme);
     END IF;


     FETCH cursorpago INTO regpago;
     existeInfo = false;

    END LOOP;

    CLOSE cursorpago;

   OPEN informes FOR SELECT * FROM ttnroinforme;
   FETCH informes INTO uninforme;
   WHILE FOUND LOOP



       PERFORM agregarinformefacturacioncobranzaitem(uninforme.nroinforme, $3,$4);
       FETCH informes INTO uninforme;

    END LOOP;

    CLOSE informes;


return true;
END;
$function$
