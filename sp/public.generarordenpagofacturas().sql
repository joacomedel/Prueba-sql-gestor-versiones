CREATE OR REPLACE FUNCTION public.generarordenpagofacturas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Genera una orden para pagar un conjunto de facturas, realizando el cambio de estados para los
mismos.*/

/*Actualiza la minuta de pago asociada a las facturas incluidas en un resumen, realizando el cambio de estados para los
mismos.*/

DECLARE
	facturas refcursor;
	unafactura RECORD;
        rfactura RECORD;
--variables 
        elnroop bigint; 
	resultado boolean;
BEGIN
/*Llamo para que se inserte la Orden de Pago*/

SELECT INTO resultado * FROM generarordenpago();
if resultado THEN
  
   /*Modifico el estado de los reintegros y su vinculacion a la Orden de pago*/
   SELECT INTO rfactura * FROM tempfactura LIMIT 1;

   OPEN facturas FOR SELECT * FROM tempfactura;
   FETCH facturas INTO unafactura;
   elnroop=unafactura.nroordenpago;
   WHILE  found LOOP
        --- VAS 06/08   agrego: , idcentroordenpago = centro()
        UPDATE factura  SET nroordenpago = unafactura.nroordenpago , idcentroordenpago = centro()
                      WHERE factura.nroregistro = unafactura.nroregistro AND factura.anio =  unafactura.anio;

       --- VAS 24/04 Se guarda el pago en la cuenta corriente del afiliado
       -- comento VAS 16/09 SELECT INTO resultado * from generarpagoctactepagonoafil(unafactura.nroordenpago);
       ----
       if (unafactura.tipocomprobante=3) then
      /*si se trata de un resumen busco las facturas incluidas en el y les actualizo el numero de orden de pago*/
             SELECT INTO resultado * from  generarordenpagofacturasresumen(unafactura.nroregistro,unafactura.anio);
       end if;

      /*El Reintegro se coloca en estado 3 - Liquidado*/
      INSERT INTO festados (fechacambio,nroregistro,anio,tipoestadofactura,observacion)
      VALUES (CURRENT_DATE,unafactura.nroregistro,unafactura.anio,3,concat('Al ser generada la orden ',unafactura.nroordenpago ,'-', centro()));

      FETCH facturas INTO unafactura;
   END LOOP;
   CLOSE facturas;
/*Malapi 25-08-2014 Agrego una funcion que carga los datos cargados en preauditoria y lo envia a las tablas definitiva de fichamedica. */

/*Dani 06-02-15 lo comento al sp para q deje de ser tan lenta la generacion de minutas de pago */
 /*  Select into resultado * FROM alta_modifica_preauditoria_fichamedica(rfactura.nroordenpago,centro());
   resultado = 'true';
*/
END IF;

/*KR 11-12-14 MODIFIQUE PARA INSERTAR ACA LAS ORDENES DE RECI VINCULADAS A LAS FACTURAS AUDITADAS CON ESA MINUTA*/

INSERT INTO ordenreciprocidadpreauditada (nroorden,anio,nroregistro,centro,idcomprobantetipos,barra,idosreci)
	SELECT DISTINCT recitemporal.nroorden, recitemporal.anio, recitemporal.nroregistro,recitemporal.centro , recitemporal.tipo,AA.barratitu,AA.idosreci 
	 FROM    (SELECT P.nrodoc, P.tipodoc,P.nroorden, P.centro, ordenesutilizadas.tipo, nroregistro, anio,nroordenpago,fechauso 
		    				FROM factura  JOIN facturaordenesutilizadas USING(nroregistro, anio) 
		    		     JOIN ordenesutilizadas USING(nroorden, centro,tipo) JOIN 
		    				(SELECT fichamedica.nrodoc, fichamedica.tipodoc,T.nroorden, T.centro, tipo 
		    				 FROM  fichamedica JOIN fichamedicapreauditada USING(idfichamedica, idcentrofichamedica) 
		    				JOIN  (SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada 
		    			     FROM  fichamedicapreauditadaitemconsulta
		    			      UNION 
		    		       SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada 
		    				   FROM fichamedicapreauditadaitem NATURAL JOIN itemvalorizada ) as T 
		    				USING(idfichamedicapreauditada, idcentrofichamedicapreauditada) ) AS P USING(nroorden,centro,tipo) 
		    				UNION 
		    				SELECT r.nrodoc, r.tipodoc, r.nrorecetario as nroorden, r.centro, CASE WHEN nullvalue(rtp.nrorecetario) THEN 14 ELSE 37 END as tipo 
		    				,nroregistro, anio, nroordenpago ,fechauso
		    				FROM factura JOIN recetario as r USING(nroregistro,anio) LEFT JOIN recetariotp as rtp  ON(r.nrorecetario=rtp.nrorecetario AND r.centro=rtp.centro) 
		    		 			) AS recitemporal 	NATURAL JOIN persona JOIN 
		    		   	( SELECT osreci.barra as barratitu,afilreci.barra ,descrip,idosreci, nrodoc, tipodoc, abreviatura FROM osreci JOIN afilreci USING(idosreci,barra) 
		    			     UNION 
--Dani remplazo 2024-09-20 porq fallaba cuando un benef pasaba a ser titu
		    			  SELECT osreci.barra as barratitu,/*persona.barra*/benefreci.barratitu as barra,descrip,idosreci, benefreci.nrodoc, benefreci.tipodoc, abreviatura 
		    				FROM osreci  JOIN afilreci  USING(idosreci,barra)
		    				JOIN benefreci ON (nrodoctitu = afilreci.nrodoc AND tipodoctitu = afilreci.tipodoc)
JOIN persona ON (persona.nrodoc = benefreci.nrodoc AND persona.tipodoc = benefreci.tipodoc)  
		    		  		 	) AS AA USING(nrodoc, tipodoc) 
	
 JOIN histobarras
--Dani descomento el using 2024-09-27	y comento el on 	
USING(nrodoc, tipodoc)
/*on(histobarras.nrodoc=AA.nrodoc and histobarras.tipodoc=AA.tipodoc and
histobarras.barra=AA.barra)	*/
		    				    					
 LEFT JOIN ordenreciprocidadpreauditada AS orpa 
                ON (recitemporal.nroorden=orpa.nroorden AND recitemporal.centro=orpa.centro AND tipo=idcomprobantetipos
                    AND recitemporal.nroregistro=orpa.nroregistro AND recitemporal.anio=orpa.anio)

WHERE recitemporal.nroordenpago=elnroop AND (cast(histobarras.fechaini as date)<= fechauso) AND (cast(histobarras.fechafin as date)>= fechauso) AND histobarras.barra>=100  AND nullvalue(orpa.nroorden);	

RETURN resultado;
END;
$function$
