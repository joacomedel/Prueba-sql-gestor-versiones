CREATE OR REPLACE FUNCTION public.generarinformecobranzactacteunc(integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$-- $1 Mes
-- $2 Año
DECLARE

--VARIABLES
    idinforme  integer default 0;
    nroinfo INTEGER;
-- REGISTROS
   regpago RECORD;
   reginformeexiste RECORD;
   uninforme RECORD;
--CURSORES
    cursorpago refcursor;
    informes refcursor;
BEGIN


    OPEN cursorpago FOR SELECT * FROM (SELECT DISTINCT ON (ccp.idpago,idformapagocobranza) idpago, ccp.idcentropago,ccp.nrodoc  , ccp.tipodoc as barra
                  , CASE WHEN nullvalue(temppagorecibo.idvalorescaja) THEN importesrecibo.idformapagotipos
                    ELSE temppagorecibo.idvalorescaja END as idformapagocobranza,fecharecibo, importerecibo
                    FROM  recibo JOIN cuentacorrientepagos AS ccp  ON(ccp.idcomprobante= recibo.idrecibo AND ccp.idcentropago=recibo.centro)
                    JOIN importesrecibo ON (recibo.centro = importesrecibo.centro AND recibo.idrecibo = importesrecibo.idrecibo)
JOIN informedescuentoplanillav2 AS idpv2 USING(idpago, idcentropago)
                    LEFT JOIN (SELECT * FROM recibocupon NATURAL JOIN valorescaja) as temppagorecibo ON (recibo.centro = temppagorecibo.centro AND recibo.idrecibo = temppagorecibo.idrecibo)
                    LEFT JOIN informefacturacioncobranza as ifc USING (idpago, idcentropago)
                    WHERE  idpv2.mes=$1 and idpv2.anio=$2 and idpv2.informedescuentoplanillatipo=1
                    AND nullvalue(ifc.idpago)
) as T;

 IF FOUND THEN
  FETCH cursorpago INTO regpago;
   --  VAS comenta 7-05-2018   SELECT INTO idinforme *  FROM crearinformefacturacion('6',500,7);

  SELECT INTO idinforme *    FROM crearinformefacturacion('8',500,7); --VAS AGREGA 7-05-2018 para que el informe haga referencia a la UNC y no a consumidor final
      
  INSERT INTO informefacturacioncobranzaunc (nroinforme,idcentroinformefacturacion)     VALUES(idinforme,centro());

  WHILE FOUND LOOP

    
     INSERT INTO informefacturacioncobranza
              (nroinforme,idcentroinformefacturacion,idpago,idcentropago,idformapagocobranza,fechadesde,fechahasta,ifcorigenpago)
     VALUES(idinforme,centro(),regpago.idpago,regpago.idcentropago,regpago.idformapagocobranza,regpago.fecharecibo,regpago.fecharecibo,1);


FETCH cursorpago INTO regpago;
END LOOP;
CLOSE cursorpago;


/*---------------------------------------------------------------------------------------------------------------
-- CS 2017-01-25 se imputan a las cuentas de Deuda
-- Consulta anterior

INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
(
select centro(), nroinforme,nrocuentac,1,sum(importe) as importe,desccuenta
from (

SELECT centro(), nroinforme, 
		mccc.nrocuentac,
		1, 
		tt.importe,
		cuentascontables.desccuenta

              FROM 
		(SELECT DISTINCT ON(idpago) idpago, idcentropago,nrocuentac,abs(importe) as importe,nroinforme,idcentroinformefacturacion as idcentro,idconcepto 	
		FROM	informefacturacioncobranza 
			JOIN cuentacorrientepagos as p USING(idpago,idcentropago)
                WHERE nroinforme = idinforme AND idcentroinformefacturacion= centro()
--                  WHERE nroinforme = 40688 AND idcentroinformefacturacion= 1 
    		  GROUP BY idpago, idcentropago,nrocuentac,importe,nroinforme, idcentroinformefacturacion,idconcepto ) AS tt
                JOIN mapeocuentascontablesconcepto AS  mccc ON (tt.idconcepto=mccc.nroconcepto)
                JOIN cuentascontables ON(mccc.nrocuentac = cuentascontables.nrocuentac)

) as x
group by centro,nroinforme,nrocuentac,desccuenta

);
--------------------------------------------------------------------------------------------------------------------
*/


-- CS 2017-01-25 se imputan a las cuentas de Deuda

INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
(

select centro(), nroinforme,nrocuentac,1,sum(importe) as importe,desccuenta
from (
-- Lo que no tiene saldo aun en pago, se imputa directamente a la cuentacontable de la deuda
SELECT centro(), nroinforme, 
		CASE WHEN nullvalue(d.nrocuentac) THEN tt.nrocuentac ELSE d.nrocuentac END,
		1, 
		sum(CASE WHEN nullvalue(ccdp.importeimp) THEN tt.importe ELSE ccdp.importeimp END) as importe,
		cuentascontables.desccuenta

              FROM 
		(SELECT DISTINCT ON(idpago) idpago, idcentropago,nrocuentac,abs(importe) as importe,nroinforme,idcentroinformefacturacion as idcentro 	
		FROM	informefacturacioncobranza 
			JOIN cuentacorrientepagos as p USING(idpago,idcentropago)
                WHERE nroinforme = idinforme AND idcentroinformefacturacion= centro()
--                WHERE nroinforme = 40688 AND idcentroinformefacturacion= 1 
                  AND abs(p.saldo)::decimal< 0.01
    		GROUP BY idpago, idcentropago,nrocuentac,importe,nroinforme, idcentroinformefacturacion) AS tt
		LEFT JOIN cuentacorrientedeudapago as ccdp ON(tt.idpago= ccdp.idpago AND tt.idcentropago=ccdp.idcentropago)
		LEFT JOIN cuentacorrientedeuda as d USING(iddeuda,idcentrodeuda)
                 JOIN cuentascontables ON(
                     ( CASE WHEN nullvalue(d.nrocuentac) THEN tt.nrocuentac ELSE d.nrocuentac END) = cuentascontables.nrocuentac)
--                WHERE nroinforme = idinforme AND idcentro= centro()
		GROUP BY (CASE WHEN nullvalue(d.nrocuentac) THEN tt.nrocuentac ELSE d.nrocuentac END), cuentascontables.desccuenta, tt.idcentro, tt.nroinforme

union
-- Lo que tiene saldo aun en pago, se imputa directamente a la cuentacontable del pago

SELECT centro(), nroinforme, 
		mccc.nrocuentac,
		1, 
		tt.importe,
		cuentascontables.desccuenta

              FROM 
		(SELECT DISTINCT ON(idpago) idpago, idcentropago,nrocuentac,abs(importe) as importe,nroinforme,idcentroinformefacturacion as idcentro,idconcepto 	
		FROM	informefacturacioncobranza 
			JOIN cuentacorrientepagos as p USING(idpago,idcentropago)
                WHERE nroinforme = idinforme AND idcentroinformefacturacion= centro()
--                  WHERE nroinforme = 40688 AND idcentroinformefacturacion= 1 
                  AND abs(p.saldo)::decimal>= 0.01
    		  GROUP BY idpago, idcentropago,nrocuentac,importe,nroinforme, idcentroinformefacturacion,idconcepto ) AS tt
                JOIN mapeocuentascontablesconcepto AS  mccc ON (tt.idconcepto=mccc.nroconcepto)
                JOIN cuentascontables ON(mccc.nrocuentac = cuentascontables.nrocuentac)

) as x
group by centro,nroinforme,nrocuentac,desccuenta


);


END IF;


return idinforme;
END;
$function$
