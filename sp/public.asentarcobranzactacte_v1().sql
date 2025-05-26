CREATE OR REPLACE FUNCTION public.asentarcobranzactacte_v1()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
Dado un rango de fechas y un centro regional y una/s cuentas contables ( INSTITUCION, ASISTENCIAL, TURISMO) ,
se migrarán todos los pagos que se efectuaron en cta cte según estos parámetros, y que aún no se han migrado a multivac.
Esto generará un informe, informefacturacioncobranza, que es una especializacion de informefacturacion;
el mismo vinculara el informe con los idpagos. 

*/
DECLARE

--VARIABLES
  
    resultado BOOLEAN;
    idinforme INTEGER;
    nroinfo INTEGER;
    latablapago VARCHAR; 
    latabladeudapago VARCHAR;
    latabladeuda VARCHAR;
    elorigenpago INTEGER;
    vconcx VARCHAR;

--REGISTROS
    uninforme RECORD;
    regpago RECORD;
    elem RECORD;
    reginformeexiste RECORD;
    rtempcobsmigrar RECORD;
    rlosrecibo RECORD;
--CURSORES
    informes refcursor;
    cursorpago refcursor;
	
BEGIN
-- Creo una tabla temporal para guardar los numeros de informes que utilizo y luego insertar los items de los mismos
IF NOT  iftableexistsparasp('ttnroinforme') THEN
   CREATE TEMP TABLE ttnroinforme (nroinforme INTEGER,idcentroinformefacturacion INTEGER,ifcorigenpago INTEGER);
END IF;

  
  --si es nulo el idrecibo entonces no selecciono previo que migrar, debo usar un rango de fechas  y centro seleccionado desde la aplicacion
  SELECT INTO rtempcobsmigrar * FROM temp_cobranzassinmigrar WHERE not nullvalue(idrecibo);
  IF FOUND THEN -- SELecciono los recibos
---DEFINO  a que corresponde el pago
      IF (rtempcobsmigrar.tipocobranza ilike '%Institucion%'  or rtempcobsmigrar.tipocobranza ilike '%Dto. U.N.C.%'  ) THEN 
          

--          latablapago = 'ctactepagonoafil';
          latablapago = 'ctactepagocliente';
          elorigenpago =2;
      ELSE 
          latablapago = 'cuentacorrientepagos';
          elorigenpago =1;
      END IF; 

     --for unapersona IN EXECUTE 'SELECT  * FROM public.persona WHERE '  $1 LOOP
      OPEN cursorpago FOR  EXECUTE concat( 'SELECT DISTINCT ON (ccp.idpago,idvalorescaja) ccp.idpago, ccp.idcentropago,
                                   idvalorescaja as idformapagocobranza,r.fecharecibo
                FROM    recibo as r NATURAL JOIN recibocupon AS rc  JOIN valorescaja USING(idvalorescaja)
                JOIN  ', latablapago  , '  as ccp ON (ccp.idcentropago = r.centro AND ccp.idcomprobante = r.idrecibo)
                JOIN temp_cobranzassinmigrar 
              
                ON (ccp.idpago = temp_cobranzassinmigrar.idpago AND ccp.idcentropago = temp_cobranzassinmigrar.idcentropago)
                LEFT JOIN informefacturacioncobranza  as ifc ON (ccp.idcentropago = ifc.idcentropago AND ccp.idpago = ifc.idpago) 
                WHERE ((nullvalue(ifc.idpago) AND nullvalue(ifc.idcentropago))) ');

    ELSE  --NO selecciono los recibos 
		OPEN cursorpago FOR SELECT CASE WHEN nullvalue(ccp.idpago) THEN ccpna.idpago ELSE ccp.idpago END as idpago,
                                 CASE WHEN nullvalue(ccp.idcentropago) THEN ccpna.idcentropago ELSE ccp.idcentropago END as idcentropago,
                                 idvalorescaja as idformapagocobranza,r.fecharecibo
                 FROM recibo as r NATURAL JOIN recibocupon AS rc  JOIN valorescaja USING(idvalorescaja)
                 JOIN temp_cobranzassinmigrar AS tcsm USING ( idrecibo, centro) 
                 LEFT JOIN cuentacorrientepagos as ccp ON(tcsm.centro = ccp.idcentropago AND tcsm.idrecibo = ccp.idcomprobante ) 			
--                   LEFT JOIN ctactepagonoafil as ccpna ON(tcsm.centro = ccpna.idcentropago AND tcsm.idrecibo = ccpna.idcomprobante)
                   LEFT JOIN ctactepagocliente as ccpna ON(tcsm.centro = ccpna.idcentropago AND tcsm.idrecibo = ccpna.idcomprobante )
                 LEFT JOIN informefacturacioncobranza AS ifc ON (CASE WHEN nullvalue(ccp.idpago) THEN ccpna.idpago ELSE ccp.idpago END  =ifc.idpago 
                        AND CASE WHEN nullvalue(ccp.idcentropago) THEN ccpna.idcentropago ELSE ccp.idcentropago END = ifc.idcentropago)  
                WHERE (nullvalue(ifc.idpago) AND nullvalue(ifc.idcentropago)) ;

   END IF;  
    
   FETCH cursorpago INTO regpago;
    
   WHILE FOUND LOOP

    
           SELECT INTO reginformeexiste nroinforme, idformapagocobranza, informefacturacion.idcentroinformefacturacion
            FROM informefacturacioncobranza NATURAL JOIN informefacturacion NATURAL JOIN informefacturacionestado
            LEFT JOIN informefacturacioncobranzaunc AS ifcu USING(nroinforme,idcentroinformefacturacion) 
            WHERE nullvalue(fechafin) AND idinformefacturacionestadotipo = 1 --AND idformapagocobranza=regpago.idformapagocobranza
           AND   fechadesde = regpago.fecharecibo::date AND fechahasta=regpago.fecharecibo::date AND nullvalue(ifcu.nroinforme)
           AND ifcorigenpago=elorigenpago;


            IF FOUND  THEN -- Si existe algun informe de dicha obra social
                         idinforme = reginformeexiste.nroinforme;

            ELSE
                         SELECT INTO idinforme *            FROM crearinformefacturacion('6',500,7);
             END IF; 
                         SELECT INTO nroinfo nroinforme from ttnroinforme WHERE ttnroinforme.nroinforme= idinforme;
                           IF NOT FOUND THEN-- si el informe no existe en la temporal que cree
                             INSERT INTO ttnroinforme values(idinforme,centro(),elorigenpago);
                           END IF;
                       

         


     INSERT INTO informefacturacioncobranza
              (nroinforme,idcentroinformefacturacion,idpago,idcentropago,idformapagocobranza,fechadesde,fechahasta,ifcorigenpago)
     VALUES(idinforme,centro(),regpago.idpago,regpago.idcentropago,regpago.idformapagocobranza,regpago.fecharecibo,regpago.fecharecibo,elorigenpago);

  
   

     FETCH cursorpago INTO regpago;
     

    END LOOP;

    CLOSE cursorpago;

--   IF (latablapago ILIKE 'ctactepagonoafil' ) THEN 
--          latabladeudapago = 'ctactedeudapagonoafil';
--          latabladeuda = 'ctactedeudanoafil';

   IF (elorigenpago =2 ) THEN 
          latabladeudapago = 'ctactedeudapagocliente';
          latabladeuda = 'ctactedeudacliente';
   ELSE 
          latabladeudapago = 'cuentacorrientedeudapago';
          latabladeuda = 'cuentacorrientedeuda';
   END IF;



-- CS 2017-01-25
-- Consulta Anterior
/*

   EXECUTE concat(' INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
       (SELECT idcentro,nroinforme,
        CASE WHEN nullvalue(d.nrocuentac) THEN tt.nrocuentac ELSE d.nrocuentac END,  1,sum(CASE WHEN nullvalue(ccdp.importeimp) THEN tt.importe ELSE ccdp.importeimp END) as importe  , cuentascontables.desccuenta
                        FROM
                            (SELECT DISTINCT ON(idpago) idpago, idcentropago,nrocuentac,abs(importe) as importe,nroinforme,idcentroinformefacturacion as idcentro
                            FROM ttnroinforme NATURAL JOIN informefacturacioncobranza JOIN ', latablapago  , ' as p USING(idpago,idcentropago)
                            GROUP BY idpago, idcentropago,nrocuentac,importe,nroinforme, idcentroinformefacturacion ) AS tt
                      LEFT JOIN  ', latabladeudapago  , ' as ccdp ON(tt.idpago= ccdp.idpago AND tt.idcentropago=ccdp.idcentropago)
                      LEFT  JOIN  ', latabladeuda  , ' as d USING(iddeuda,idcentrodeuda)
                        JOIN cuentascontables ON(
                     ( CASE WHEN nullvalue(d.nrocuentac) THEN tt.nrocuentac ELSE d.nrocuentac END) = cuentascontables.nrocuentac)
                        GROUP BY  ( CASE WHEN nullvalue(d.nrocuentac) THEN tt.nrocuentac ELSE d.nrocuentac END), cuentascontables.desccuenta, tt.idcentro, tt.nroinforme) ');

*/



-- CS 2017-01-25
-- Modificacion en la consulta que carga los Items informe facturacion
-- Para que discrimine las cuentas segun las imputaciones en lugar de hacerlo segun las cuentas
-- de los pagos

-- CS 2018-05-18
-- Para que tome la nrocuentac del mapeocuentascontablesconcepto

vconcx='0';
if (existecolumtemp(latablapago,'idconcepto')) then
	vconcx='p.idconcepto';
end if;
----------------------------------------------------------------

EXECUTE concat('

INSERT INTO informefacturacionitem(idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
(



select centro(), nroinforme,nrocuentac,1,sum(importe) as importe,desccuenta
from (




-- Lo que no tiene saldo aun en pago, se imputa directamente a la cuentacontable de la deuda
SELECT centro(), nroinforme,CASE WHEN nullvalue(d.nrocuentac) THEN tt.nrocuentac ELSE d.nrocuentac END,1, 
		sum(CASE WHEN nullvalue(ccdp.importeimp) THEN tt.importe ELSE ccdp.importeimp END) as importe,
		cuentascontables.desccuenta
FROM 	(
	SELECT DISTINCT ON(idpago) idpago, idcentropago,nrocuentac,abs(importe) as importe,nroinforme,idcentroinformefacturacion as idcentro 	
	FROM ttnroinforme NATURAL JOIN informefacturacioncobranza 
		JOIN ',latablapago,' as p USING(idpago,idcentropago)
        WHERE true 
	-- and nroinforme = 51849 AND idcentroinformefacturacion= centro()
	   AND abs(p.saldo)::decimal< 0.01
    	GROUP BY idpago, idcentropago,nrocuentac,importe,nroinforme, idcentroinformefacturacion
	) AS tt
	LEFT JOIN ',latabladeudapago,' as ccdp ON(tt.idpago= ccdp.idpago AND tt.idcentropago=ccdp.idcentropago)
	LEFT JOIN ',latabladeuda,' as d USING(iddeuda,idcentrodeuda)
        JOIN cuentascontables ON((CASE WHEN nullvalue(d.nrocuentac) THEN tt.nrocuentac ELSE d.nrocuentac END) = cuentascontables.nrocuentac)
GROUP BY (CASE WHEN nullvalue(d.nrocuentac) THEN tt.nrocuentac ELSE d.nrocuentac END), cuentascontables.desccuenta, tt.idcentro, tt.nroinforme


union
-- Lo que tiene saldo aun en pago, se imputa directamente a la cuentacontable del pago
select centro(), nroinforme,nrocuentac,1,sum(importe) as importe,desccuenta
from 	(
	SELECT centro(), nroinforme, case when nullvalue(mccc.nrocuentac) then tt.nrocuentac else mccc.nrocuentac end as nrocuentac,
		1, tt.importe,case when nullvalue(cc1.desccuenta) then cc2.desccuenta else cc1.desccuenta end as desccuenta
        FROM 
		(
		SELECT DISTINCT ON(idpago) idpago, idcentropago,nrocuentac,abs(importe) as importe,
nroinforme,idcentroinformefacturacion as idcentro,
                -- 0 as idconcepto 	
                ',vconcx,' as idconcepto 	
		FROM ttnroinforme NATURAL JOIN informefacturacioncobranza
		     JOIN ',latablapago,' as p USING(idpago,idcentropago)
                WHERE true
--			and nroinforme = 51849 AND idcentroinformefacturacion= centro()
	                AND abs(p.saldo)::decimal>= 0.01
    		  GROUP BY idpago, idcentropago,nrocuentac,importe,nroinforme, idcentroinformefacturacion,idconcepto 
		) AS tt
        LEFT JOIN mapeocuentascontablesconcepto AS  mccc ON (tt.idconcepto=mccc.nroconcepto)
        LEFT JOIN cuentascontables as cc1 ON(mccc.nrocuentac = cc1.nrocuentac)
        LEFT JOIN cuentascontables as cc2 ON(tt.nrocuentac = cc2.nrocuentac)
	) as r
GROUP BY nroinforme,nrocuentac,desccuenta

) as x
group by centro,nroinforme,nrocuentac,desccuenta



)

');




return true;
END;
$function$
