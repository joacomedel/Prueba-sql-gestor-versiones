CREATE OR REPLACE FUNCTION public.expendio_facturarexpendioorden()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
lasordenes refcursor;

--REGISTRO
unaorden record;
unitem record;
titularfactura record;

--VARIABLES
esvalorizada boolean;
resp boolean;
importetotalapagar DOUBLE PRECISION;
indice integer;
laordenpago VARCHAR;
vgenerarpendiente BOOLEAN DEFAULT true;
BEGIN
    indice = 0;
   OPEN lasordenes FOR SELECT * FROM ttordenesgeneradas NATURAL JOIN 
                      temporden WHERE NOT autogestion;
          FETCH lasordenes INTO unaorden;

          WHILE  found LOOP
           
           --KR 13-02-23 SI La orden es un anticipo de reintegro no se genera un pendiente en caja  y la orden no es de presupuesto
          
          IF existecolumtemp('temporden','anticiporeintegro') THEN 
        
            --IF ((unaorden.anticiporeintegro is not null or unaorden.anticiporeintegro) and unaorden.tipo=20) THEN 
    /*Dani modifico 28032023 porq no genera el pendiente en caja de ordenes de presupuesto ,NO era anticipo reitnegro y
  donde el afiliado debia abonar un   porcentaje de la practica*/
    IF ((unaorden.anticiporeintegro is not null and unaorden.anticiporeintegro) and unaorden.tipo=20) 
   
 THEN 
                 vgenerarpendiente=false;
            END IF;
          END IF;
          IF vgenerarpendiente THEN
                   indice = indice +1;
                   SELECT INTO titularfactura  CASE WHEN nullvalue(TT.nrodoctitu) THEN consumo.nrodoc ELSE nrodoctitu END as nrodoc,
                   CASE WHEN nullvalue(TT.tipodoctitu) THEN consumo.tipodoc ELSE tipodoctitu END as tipodoc
                   FROM consumo LEFT JOIN (
                   SELECT nrodoc, tipodoc, nrodoctitu, tipodoctitu FROM benefsosunc
                   UNION
                   SELECT nrodoc, tipodoc, nrodoctitu, tipodoctitu  FROM benefreci
                   ) AS TT USING (nrodoc, tipodoc)
                   WHERE nroorden=unaorden.nroorden and centro=unaorden.centro;

              INSERT INTO ordenessinfacturas(nroorden,centro,nrodoc,tipodoc)
              VALUES(unaorden.nroorden,unaorden.centro,titularfactura.nrodoc,titularfactura.tipodoc);

              SELECT INTO unitem nroorden,centro,nrocuentac as idconcepto , importesorden.importe,cantidad,desccuenta
               FROM importesorden LEFT JOIN
               (SELECT nrocuentac,sum(cantidad) as  cantidad,desccuenta,nroorden,centro
                FROM item JOIN itemvalorizada USING(iditem, centro) NATURAL JOIN orden  JOIN  practica USING(idnomenclador,idcapitulo,idsubcapitulo, idpractica)
                NATURAL JOIN cuentascontables  WHERE tipo <> 4 AND nroorden=unaorden.nroorden and centro=unaorden.centro GROUP BY nrocuentac,desccuenta,nroorden,centro
                UNION
                SELECT '40311' as nrocuentac, 1,'Consulta' as desccuenta, nroorden,centro FROM orden NATURAL JOIN ordconsulta  WHERE nroorden=unaorden.nroorden and centro=unaorden.centro
                UNION
                SELECT '40316' as nrocuentac, 1,'Recetario TP' as desccuenta,nrorecetario as nroorden,centro FROM recetariotp  WHERE nrorecetario=unaorden.nroorden and centro=unaorden.centro
              ) as TT USING (nroorden, centro)
               WHERE nroorden=unaorden.nroorden and centro=unaorden.centro and (idformapagotipos =2 or idformapagotipos=3);
               
                  
                     RAISE NOTICE 'Concepto % ORDEN (%) indice %',unitem.idconcepto,unaorden,indice;
                   


               INSERT INTO itemordenessinfactura(nroorden,centro,idconcepto,importe,cantidad,descripcion) (
             
               SELECT nroorden,centro,nrocuentac as idconcepto , importesorden.importe,cantidad,desccuenta
               FROM importesorden LEFT JOIN
               (SELECT nrocuentac,sum(cantidad) as  cantidad,desccuenta,nroorden,centro
                FROM item JOIN itemvalorizada USING(iditem, centro) NATURAL JOIN orden  JOIN  practica USING(idnomenclador,idcapitulo,idsubcapitulo, idpractica)
                NATURAL JOIN cuentascontables  WHERE tipo <> 4 AND nroorden=unaorden.nroorden and centro=unaorden.centro GROUP BY nrocuentac,desccuenta,nroorden,centro
                UNION
                SELECT '40311' as nrocuentac, 1,'Consulta' as desccuenta, nroorden,centro FROM orden NATURAL JOIN ordconsulta  WHERE nroorden=unaorden.nroorden and centro=unaorden.centro
                UNION
                SELECT '40316' as nrocuentac, 1,'Recetario TP' as desccuenta,nrorecetario as nroorden,centro FROM recetariotp  WHERE nrorecetario=unaorden.nroorden and centro=unaorden.centro
              ) as TT USING (nroorden, centro)
               WHERE nroorden=unaorden.nroorden and centro=unaorden.centro and (idformapagotipos =2 or idformapagotipos=3)
               );

                

               --IF FOUND THEN
                 --INSERT INTO itemordenessinfactura(nroorden,centro,idconcepto,cantidad,importe,descripcion)
                 --VALUES (unitem.nroorden,unitem.centro,unitem.nrocuentac,unitem.cantidad,unitem.importe,unitem.desccuenta);
               --END IF;
              
            END IF;
          FETCH lasordenes INTO unaorden;
          END LOOP;
          CLOSE lasordenes;

--KR 10-11-22 Genera la MP y OPC para el reintegro anticipado
 SELECT INTO laordenpago * FROM expendio_reintegroanticipado('');
    return true;
END;$function$
