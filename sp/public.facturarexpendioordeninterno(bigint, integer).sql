CREATE OR REPLACE FUNCTION public.facturarexpendioordeninterno(bigint, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
lasordenes refcursor;

--REGISTRO
unaorden record;
unitem record;
titularfactura record; 
rtest record;

--VARIABLES
esvalorizada boolean;
resp boolean;
importetotalapagar DOUBLE PRECISION;

BEGIN

                
           SELECT INTO titularfactura  CASE WHEN nullvalue(TT.nrodoctitu) THEN consumo.nrodoc ELSE nrodoctitu END as nrodoc,
                   CASE WHEN nullvalue(TT.tipodoctitu) THEN consumo.tipodoc ELSE tipodoctitu END as tipodoc,tipo
                   FROM consumo 
                   NATURAL JOIN orden 
                   LEFT JOIN (
                   SELECT nrodoc, tipodoc, nrodoctitu, tipodoctitu FROM benefsosunc 
                   UNION 
                   SELECT nrodoc, tipodoc, nrodoctitu, tipodoctitu  FROM benefreci
                   ) AS TT USING (nrodoc, tipodoc) 
            WHERE  nroorden=$1 and centro=$2;

             IF FOUND AND (titularfactura.tipo = 37 OR titularfactura.tipo = 53 or titularfactura.tipo =56) THEN 

--KR 11-06-21 las ordenes de SUAP que se facturan deben volver a pendientes, estado =9 Pendientes sin facturar
               IF (titularfactura.tipo=56) THEN 
                 PERFORM expendio_cambiarestadoorden($1,$2,9);
               ELSE
                 PERFORM expendio_cambiarestadoorden($1,$2,1);
               --agrego hector porq no aparecen los recetarios tp al anular en ordenes sin factura
               --MaLaPi 18-12-2017 Verifico pues el pendiente de facturacion puede estar aun en la tabla, para que no de error al intentar anular la factura. Pasa con las delegaciones o cuando se facturar por error con un talonario que no elimina pendiente de estas tablas. (OTP)
                SELECT INTO rtest * FROM ordenessinfacturas WHERE nroorden=$1 and centro=$2;

                IF NOT FOUND THEN 
                  INSERT INTO ordenessinfacturas(nroorden,centro,nrodoc,tipodoc)
                  VALUES($1,$2,titularfactura.nrodoc,titularfactura.tipodoc);

SELECT INTO unitem nrocuentac, importesorden.importe, nroorden,centro,cantidad,desccuenta
                 FROM importesorden LEFT JOIN 
                 (SELECT nrocuentac, cantidad,desccuenta,nroorden,centro
                 FROM item JOIN itemvalorizada USING(iditem, centro)  JOIN  practica USING(idnomenclador,idcapitulo,idsubcapitulo, idpractica) 
                  NATURAL JOIN cuentascontables  WHERE nroorden=$1 and centro=$2
                  UNION 
                  SELECT '40311' as nrocuentac, 1,'Consulta' as desccuenta, nroorden,centro FROM orden NATURAL JOIN ordconsulta  WHERE nroorden=$1 and centro=$2
                  UNION 
                  SELECT '40316' as nrocuentac, 1,'Recetario TP' as desccuenta,nrorecetario as nroorden,centro FROM recetariotp  WHERE nrorecetario=$1 and centro=$2
                 ) as TT USING (nroorden, centro)
                WHERE nroorden=$1 and centro=$2 and (idformapagotipos =2 or idformapagotipos=3);
          

                 IF FOUND THEN 
                   INSERT INTO itemordenessinfactura(nroorden,centro,idconcepto,cantidad,importe,descripcion)
                   VALUES (unitem.nroorden,unitem.centro,unitem.nrocuentac,unitem.cantidad,round(CAST(unitem.importe AS numeric),2),unitem.desccuenta);
                 END IF; 
                END IF; -- De si esta ya cargada en ordenessinfacturas
               END IF;
             ELSE 
              --MaLaPi 18-12-2017 Verifico pues el pendiente de facturacion puede estar aun en la tabla, para que no de error al intentar anular la factura. Pasa con las delegaciones o cuando se facturar por error con un talonario que no elimina pendiente de estas tablas. (OTP)
              SELECT INTO rtest * FROM ordenessinfacturas WHERE nroorden=$1 and centro=$2;

              IF NOT FOUND THEN 

              INSERT INTO ordenessinfacturas(nroorden,centro,nrodoc,tipodoc)
              VALUES($1,$2,titularfactura.nrodoc,titularfactura.tipodoc);
          
                     
               SELECT INTO unitem nrocuentac, importesorden.importe, nroorden,centro,cantidad,desccuenta
               FROM importesorden LEFT JOIN 
               (SELECT nrocuentac, cantidad,desccuenta,nroorden,centro
                FROM item JOIN itemvalorizada USING(iditem, centro)  JOIN  practica USING(idnomenclador,idcapitulo,idsubcapitulo, idpractica) 
                NATURAL JOIN cuentascontables  WHERE nroorden=$1 and centro=$2
                UNION 
--KR 10-12-19 modifico la cta 50340 a 40311
                SELECT '40311' as nrocuentac, 1,'Consulta' as desccuenta, nroorden,centro FROM orden NATURAL JOIN ordconsulta  WHERE nroorden=$1 and centro=$2
                UNION 
                SELECT '40316' as nrocuentac, 1,'Recetario TP' as desccuenta,nrorecetario as nroorden,centro FROM recetariotp  WHERE nrorecetario=$1 and centro=$2
              ) as TT USING (nroorden, centro)
               WHERE nroorden=$1 and centro=$2 and (idformapagotipos =2 or idformapagotipos=3);
          

            IF FOUND THEN 
               INSERT INTO itemordenessinfactura(nroorden,centro,idconcepto,cantidad,importe,descripcion)
               VALUES (unitem.nroorden,unitem.centro,unitem.nrocuentac,unitem.cantidad,round(CAST(unitem.importe AS numeric),2),unitem.desccuenta);


            END IF; 
            
            END IF; -- De si esta ya cargada en ordenessinfacturas
           END IF;

    return true;
END;

$function$
