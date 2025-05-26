CREATE OR REPLACE FUNCTION public.generarinforme_expendioreintegro()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$DECLARE
    
--registros
	dato RECORD;
	relafiliado RECORD;
        unaorden RECORD;
        rtodook  RECORD;
--variables
	informeF  integer;
	resp BOOLEAN;

--cursor
        cordenreintegro refcursor;
BEGIN

	SELECT INTO relafiliado CASE WHEN nullvalue(nrodoctitu) THEN p.nrodoc ELSE bs.nrodoctitu END AS nrodoc, CASE WHEN nullvalue(nrodoctitu) THEN p.tipodoc  ELSE bs.tipodoctitu END AS barra 
                 FROM temporden NATURAL JOIN persona AS p
                LEFT JOIN benefsosunc AS bs USING(nrodoc, tipodoc) ;

	-- Creo el informe de facturacion
	SELECT INTO informeF * FROM crearinformefacturacion(relafiliado.nrodoc,relafiliado.barra,13);

      
    
	-- Creo el informe facturacion expendio reintegro 

        OPEN cordenreintegro FOR SELECT * FROM ttordenesgeneradas NATURAL JOIN reintegroorden;
	FETCH cordenreintegro INTO  unaorden;	
	WHILE FOUND LOOP 
	      INSERT INTO informefacturacionexpendioreintegro(nroinforme, idcentroinformefacturacion/*, nroorden, centro*/,nroreintegro,anio, idcentroregional )
	      VALUES(informeF, centro(),/* unaorden.nroorden,unaorden.centro,*/ unaorden.nroreintegro, unaorden.anio, unaorden.idcentroregional);
            FETCH cordenreintegro INTO  unaorden;	

        END LOOP;
	CLOSE cordenreintegro;


          --Cambio la forma de pago del informe a la forma de pago de la orden reintegro 
        UPDATE informefacturacion SET idformapagotipos =T.idformapagotipos, idtipofactura='OT', tipofactura='OT'
                FROM (
                    SELECT idformapagotipos, nroinforme, idcentroinformefacturacion
                     FROM importesorden NATURAL JOIN reintegroorden NATURAL JOIN informefacturacionexpendioreintegro NATURAL JOIN consumo  
                     WHERE nroinforme=informeF AND idcentroinformefacturacion=centro() AND  idformapagotipos<>6 AND idformapagotipos<>1 AND not anulado
                   ) T
          WHERE informefacturacion.nroinforme = T.nroinforme AND informefacturacion.idcentroinformefacturacion = T.idcentroinformefacturacion;


	/*INSERT INTO informefacturacionitem(idcentroinformefacturacionitem,idcentroinformefacturacion,nroinforme,nrocuentac,cantidad,importe,descripcion)
        SELECT  centro(),centro(),informeF, nrocuentac, cantidad, importesorden.importe, desccuenta
           FROM importesorden NATURAL JOIN informefacturacionexpendioreintegro
           LEFT JOIN
           (SELECT DISTINCT nrocuentac, cantidad,desccuenta,nroorden,centro
            FROM item JOIN itemvalorizada USING(iditem, centro)  JOIN  practica USING(idnomenclador,idcapitulo,idsubcapitulo, idpractica)
            NATURAL JOIN cuentascontables  
            --WHERE nroorden=unaorden.nroorden and centro=unaorden.centro
            ) as TT USING (nroorden, centro)
        WHERE nroinforme = informeF AND idcentroinformefacturacion = centro()  and idformapagotipos<>6 and idformapagotipos<>1;
*/
        INSERT INTO informefacturacionitem(nrocuentac,nroinforme,cantidad,descripcion,importe,idcentroinformefacturacionitem,idcentroinformefacturacion)

SELECT  DISTINCT nrocuentac, informeF, cantidad,desccuenta, round(CAST (sum(afiliado)  AS numeric),2)

 ,centro(),centro() 
            FROM tempitems JOIN  practica USING(idnomenclador,idcapitulo,idsubcapitulo, idpractica)
            NATURAL JOIN cuentascontables  
            
           GROUP BY nrocuentac, cantidad,desccuenta,centro(),centro();
  


-- Cambio el estado del informe de facturacion 3=facturable
	FOR indiceestado IN 1..3 LOOP
            SELECT INTO resp *
            FROM cambiarestadoinformefacturacion(informeF,centro(),indiceestado,'Generado Automaticamente desde generarinforme_expendioreintegro');
        END LOOP;

return informeF;
END;
$function$
