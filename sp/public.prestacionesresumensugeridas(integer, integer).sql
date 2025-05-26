CREATE OR REPLACE FUNCTION public.prestacionesresumensugeridas(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
losresumenes refcursor;

--REGISTRO
unresumen record;
esresumen record;
--VARIABLES
esfactura boolean;
resp boolean;
importetotalapagar DOUBLE PRECISION;

BEGIN
  PERFORM imputacionauditoriamedica($1,$2);
  
  SELECT INTO esresumen * FROM factura WHERE  idresumen =$1  and anioresumen=$2;
  IF FOUND THEN
  INSERT INTO facturaprestaciones (anio,nroregistro,fidtipoprestacion,importe,debito)

  SELECT anio,nroregistro, fidtipo, SUM(apagar) as apagar, sum(impdebito) as debito 
     FROM (SELECT  SUM(importe)  AS apagar,  nroregistro, anio, sum(facturaordenimputacion.importedebito) as impdebito, fidtipo
                    FROM facturaordenimputacion  JOIN factura USING(nroregistro, anio) 
                    WHERE idresumen=$1 AND anioresumen=$2 
                    GROUP BY fidtipo, nroregistro, anio
           UNION
           SELECT sum(importedebito) as apagar,nroregistro,anio,sum(importedebito) as impdebito, fidtipo
                   FROM facturadebitoimputacionpendiente JOIN ftipoprestacion ON (fidtipo=fidtipoprestacion)
                   JOIN factura USING(nroregistro, anio)
                   WHERE idresumen=$1 AND anioresumen=$2 
                   GROUP BY fidtipo, nroregistro, anio ) AS TT
      GROUP BY fidtipo, nroregistro, anio;
    
UPDATE factura SET fimportepagar =T.apagar FROM  

(SELECT anio,nroregistro,  SUM(apagar) as apagar
FROM (SELECT  SUM(importe - (case when nullvalue(facturaprestaciones.debito) then 0 else debito end))   AS apagar
, nroregistro, anio
   FROM facturaprestaciones JOIN factura USING(nroregistro, anio)
        WHERE idresumen=$1 AND anioresumen=$2 
       GROUP BY nroregistro, anio  ) AS TT
       GROUP BY  nroregistro, anio
) as T 
WHERE T.nroregistro= factura.nroregistro AND T.anio=factura.anio;

UPDATE factura set fimportepagar= (SELECT  SUM(fimportepagar) as apagar
FROM factura  WHERE idresumen=$1 AND anioresumen=$2   ) 
where nroregistro=$1 AND anio=$2;

INSERT INTO debitofacturaprestador (anio,nroregistro,fidtipoprestacion,importe,observacion,idmotivodebitofacturacion)
SELECT anio, nroregistro, fidtipo,SUM(importedebito) as debito,'',idmotivodebitofacturacion::integer
FROM facturadebitoimputacion JOIN factura USING(nroregistro, anio)
WHERE  idresumen=$1 AND anioresumen=$2  AND facturadebitoimputacion.importedebito >0
GROUP BY idmotivodebitofacturacion, anio, nroregistro, fidtipo;
/*
ELSE
 INSERT INTO facturaprestaciones (anio,nroregistro,fidtipoprestacion,importe,debito)

  SELECT anio,nroregistro, fidtipo, SUM(apagar) as apagar, sum(impdebito) as debito 
     FROM (SELECT  SUM(importe)  AS apagar,  nroregistro, anio, sum(facturaordenimputacion.importedebito) as impdebito, fidtipo
                    FROM facturaordenimputacion  JOIN factura USING(nroregistro, anio) 
                    WHERE nroregistro=$1 AND anio=$2 
                    GROUP BY fidtipo, nroregistro, anio
           UNION
           SELECT sum(importedebito) as apagar,nroregistro,anio,sum(importedebito) as impdebito, fidtipo
                   FROM facturadebitoimputacionpendiente JOIN ftipoprestacion ON (fidtipo=fidtipoprestacion)
                   JOIN factura USING(nroregistro, anio)
                   WHERE nroregistro=$1 AND anio=$2 
                   GROUP BY fidtipo, nroregistro, anio ) AS TT
      GROUP BY fidtipo, nroregistro, anio;
    
UPDATE factura SET fimportepagar =T.apagar FROM  

(SELECT  SUM(importe - (case when nullvalue(facturaprestaciones.debito) then 0 else debito end))   AS apagar

   FROM facturaprestaciones JOIN factura USING(nroregistro, anio)
        WHERE nroregistro=$1 AND anio=$2 
       
) as T 
WHERE nroregistro= $1 AND anio=$2;


INSERT INTO debitofacturaprestador (anio,nroregistro,fidtipoprestacion,importe,observacion,idmotivodebitofacturacion)
SELECT anio, nroregistro, fidtipo,SUM(importedebito) as debito,'',idmotivodebitofacturacion::integer
FROM facturadebitoimputacion JOIN factura USING(nroregistro, anio)
WHERE  nroregistro=$1 AND anio=$2  AND facturadebitoimputacion.importedebito >0
GROUP BY idmotivodebitofacturacion, anio, nroregistro, fidtipo;
*/
END IF;


    return true;
END;



$function$
