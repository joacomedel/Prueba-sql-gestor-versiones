CREATE OR REPLACE FUNCTION public.generarinformecobranza_viejo(character varying, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES
    existeinfoso BOOLEAN;
    resultado BOOLEAN;
    fechadesde alias for $1;
    fechahasta alias for $2;
    idcentro alias for $3;
    idinforme INTEGER;
    nroinfo INTEGER;
    esosreci BOOLEAN;
    idPagoCobranza BIGINT;
    existeInfo BOOLEAN;

--REGISTROS
    uninforme RECORD;
    regrecibo RECORD;
    elem RECORD;
    reginformeexiste RECORD;

--CURSORES
    informes refcursor;
    cursorExisteInfo refcursor;
    cursorrecibo CURSOR FOR 
    SELECT cuentacorrientepagos.idpago, cuentacorrientepagos.idcentropago, cliente.nrocliente as nrodoc, cliente.barra
,case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
else temppagorecibo.idformapagotipos
end as idformapagocobranza
FROM cliente JOIN facturaventa ON(cliente.nrocliente=facturaventa.nrodoc AND cliente.barra=facturaventa.barra)
JOIN informefacturacion USING (nrofactura, tipocomprobante, nrosucursal, tipofactura)
JOIN cuentacorrientedeuda
ON(informefacturacion.nroinforme*100+informefacturacion.idcentroinformefacturacion=cuentacorrientedeuda.idcomprobante
AND cuentacorrientedeuda.idcomprobantetipos = 21)
JOIN cuentacorrientedeudapago USING (iddeuda, idcentrodeuda)
JOIN cuentacorrientepagos USING (idpago, idcentropago)
JOIN recibo ON(cuentacorrientepagos.idcomprobante= recibo.idrecibo AND cuentacorrientepagos.idcentropago=recibo.centro)
JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
LEFT JOIN
(SELECT * FROM recibocupon NATURAL JOIN valorescaja) as temppagorecibo
ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)
LEFT JOIN informefacturacioncobranza  USING (idpago,idcentropago)

WHERE ((nullvalue(informefacturacioncobranza.idpago) AND nullvalue(informefacturacioncobranza.idcentropago)))
AND cuentacorrientepagos.idconcepto <> 999 AND cuentacorrientepagos.idconcepto = 387

AND cuentacorrientedeudapago.fechamovimientoimputacion:: date >='2010-11-01' AND
cuentacorrientedeudapago.fechamovimientoimputacion:: date <='2010-11-30'
AND (cuentacorrientepagos.idcentropago=1 or 1=0);

/*
    
    
SELECT DISTINCT recibo.idrecibo,recibo.centro, cliente.nrocliente as nrodoc, cliente.barra,
case when nullvalue(temppagorecibo.idvalorescaja) then importesrecibo.idformapagotipos
else temppagorecibo.idformapagotipos
end as idformapagocobranza
FROM cliente JOIN facturaventa ON(cliente.nrocliente=facturaventa.nrodoc AND cliente.barra=facturaventa.barra)
JOIN informefacturacion USING (nrofactura, tipocomprobante, nrosucursal, tipofactura)
JOIN cuentacorrientedeuda
ON(informefacturacion.nroinforme*100+informefacturacion.idcentroinformefacturacion=cuentacorrientedeuda.idcomprobante
AND cuentacorrientedeuda.idcomprobantetipos = 21)
JOIN cuentacorrientedeudapago USING (iddeuda, idcentrodeuda) JOIN cuentacorrientepagos USING (idpago, idcentropago)
JOIN recibo ON (cuentacorrientepagos.idcomprobante=recibo.idrecibo AND cuentacorrientepagos.idcentropago=recibo.centro)
JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
left join
(SELECT * FROM recibocupon NATURAL JOIN valorescaja) as temppagorecibo
ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)
left join informefacturacioncobranza on(recibo.idrecibo=informefacturacioncobranza.idrecibo and
recibo.centro=informefacturacioncobranza.centro)
WHERE (nullvalue(informefacturacioncobranza.idrecibo) and nullvalue(informefacturacioncobranza.centro)) and
recibo.fecharecibo:: date <= fechahasta AND recibo.fecharecibo:: date >= fechadesde
AND (recibo.centro=idcentro or idcentro=0)

UNION

SELECT DISTINCT recibo.idrecibo,recibo.centro,pagosdesc.nrodoc,pagosdesc.barra,
case when nullvalue(temppagorecibo.idvalorescaja) and importesrecibo.idformapagotipos <> 8 then importesrecibo.idformapagotipos
else case when nullvalue(temppagorecibo.idvalorescaja) and not nullvalue(cuentabancariasosunc.nrocuentac) and importesrecibo.idformapagotipos=8 then cuentabancariasosunc.nrocuentac::integer
else case when nullvalue(temppagorecibo.idvalorescaja) and nullvalue(cuentabancariasosunc.nrocuentac) then importesrecibo.idformapagotipos
else temppagorecibo.idformapagotipos
end
end
end as idformapagocobranza
FROM pagos NATURAL JOIN
(SELECT pagosafiliado.idpagos, pagosafiliado.centro, pagosafiliado.nrodoc, persona.barra
   FROM pagosafiliado
NATURAL JOIN persona
) pagosdesc
NATURAL JOIN recibo JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
LEFT JOIN (SELECT * FROM recibocupon NATURAL JOIN valorescaja) as temppagorecibo
ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)

left join informefacturacioncobranza on(recibo.idrecibo=informefacturacioncobranza.idrecibo and
recibo.centro=informefacturacioncobranza.centro)
LEFT JOIN cuentabancariasosunc ON (pagos.idbanco= cuentabancariasosunc.idbanco AND pagos.nrocuentabanco=cuentabancariasosunc.nrocuentabanco)
WHERE (nullvalue(informefacturacioncobranza.idrecibo) and nullvalue(informefacturacioncobranza.centro)) and
recibo.fecharecibo:: date <= fechahasta AND recibo.fecharecibo:: date >= fechadesde
AND (recibo.centro=idcentro or idcentro=0) 
ORDER BY idformapagocobranza,centro;

*/
	
BEGIN

-- Creo una tabla temporal para guardar los numeros de informes que utilizo y luego insertar los items de los mismos
   CREATE TEMP TABLE ttnroinforme (nroinforme INTEGER);
-- Creo los item del informe de facturacion, para ello uso la temporal que utiliza el SP que inserta en la tabla informefacturacioitem
    CREATE TEMP TABLE ttinformefacturacionitem (nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR);
    idPagoCobranza =0;
    existeinfoso = false;
    existeInfo = false;
    esosreci = true;
    OPEN cursorrecibo;
    FETCH cursorrecibo INTO regrecibo;
    idPagoCobranza = regrecibo.idformapagocobranza;
    WHILE FOUND LOOP
   
     IF regrecibo.barra > 100 THEN
 --verifico que el nrodoc pertenezca a una obra social y no a un afiliado de reciprocidad (informefacturacionreciprocidad)
     SELECT INTO elem * FROM persona WHERE nrodoc=regrecibo.nrodoc::varchar AND barra= regrecibo.barra;
       IF NOT FOUND THEN  --la cobranza es de una obra social por reciprocidad
       -- Busco si existe algun informe que no este en estado sincronizado de la obra social por reciprocidad


        OPEN cursorExisteInfo FOR SELECT nroinforme, idformapagocobranza, informefacturacion.idcentroinformefacturacion
        FROM informefacturacioncobranza natural join informefacturacion natural join informefacturacionestado
        where nullvalue(fechafin) and idinformefacturacionestadotipo = 1  and fechainforme = current_date and nrocliente =regrecibo.nrodoc and barra =regrecibo.barra;
       
        
        FETCH cursorExisteInfo INTO reginformeexiste;
        esosreci = true;
                WHILE FOUND AND NOT existeInfo LOOP -- Si existe algun informe de dicha obra social
                   IF (reginformeexiste.idformapagocobranza <> regrecibo.idformapagocobranza) THEN --Si NO Existe ningun info con la misma forma de pago
                      --creo el informe de facturacion, 7 es el numero que corresponde al tipo de informe de COBRANZA (ver tabla informefacturaciontipo)
                           SELECT INTO idinforme * FROM crearinformefacturacion(regrecibo.nrodoc,regrecibo.barra,7);
                   ELSE
                           idinforme = reginformeexiste.nroinforme;
                           existeInfo= true;
                    END IF;
                FETCH cursorExisteInfo INTO reginformeexiste;
                END LOOP;
                CLOSE cursorExisteInfo;
                IF NOT existeInfo THEN--si NO existe un informe en dicha obra social
                         SELECT INTO idinforme * FROM crearinformefacturacion(regrecibo.nrodoc,regrecibo.barra,7);
                         idPagoCobranza =regrecibo.idformapagocobranza;
                 END IF;
                   
                
                
       ELSE  
               esosreci= false;
       END IF;


      ELSE --Corresponde a un afiliado de Sosunc, se crea un informe de cobranza a los "afiliados"
           esosreci = true;
          IF NOT existeinfoso THEN
                    SELECT INTO idinforme * FROM crearinformefacturacion(6::varchar,500::bigint,7);
                    existeinfoso = true;
          ELSE
               IF (regrecibo.idformapagocobranza <> idPagoCobranza) THEN --Si es la misma forma de pago
                          SELECT INTO idinforme * FROM crearinformefacturacion(regrecibo.nrodoc,regrecibo.barra,7);
                          existeinfoso = true;
                          idPagoCobranza =regrecibo.idformapagocobranza;
               END IF;
          END IF;
      END IF;
      IF esosreci THEN --si es una os reciprocidad y no un afiliado de reciprocidad o un afiliado sosunc
           INSERT INTO informefacturacioncobranza(nroinforme,idcentroinformefacturacion,idrecibo,centro,idformapagocobranza) VALUES(idinforme,centro(),regrecibo.idrecibo,regrecibo.centro,regrecibo.idformapagocobranza);
      END IF;

     SELECT INTO nroinfo nroinforme from ttnroinforme WHERE ttnroinforme.nroinforme= idinforme;
     IF NOT FOUND THEN-- si el informe no existe en la temporal que cree
                INSERT INTO ttnroinforme values(idinforme);
     END IF;

    
     FETCH cursorrecibo INTO regrecibo;
     existeInfo = false;

    END LOOP;

    CLOSE cursorrecibo;

   OPEN informes FOR SELECT * FROM ttnroinforme;
   FETCH informes INTO uninforme;
   WHILE FOUND LOOP



       PERFORM agregarinformefacturacioncobranzaitem(uninforme.nroinforme, idcentro);
      /* PERFORM cambiarestadoinformefacturacion (uninforme.nroinforme, centro(), 8, 'Generado Automaticamente desde generarinformecobranza');
*/
        FETCH informes INTO uninforme;

    END LOOP;

    CLOSE informes;

   
return true;
END;
$function$
