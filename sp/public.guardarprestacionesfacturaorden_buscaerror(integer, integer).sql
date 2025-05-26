CREATE OR REPLACE FUNCTION public.guardarprestacionesfacturaorden_buscaerror(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
lasprestaciones refcursor;
losdebitos refcursor;

--REGISTRO
unaprestacion record;
undebito record;
elresumen record; 

--VARIABLES
estadofactres INTEGER;
--nodatos BOOLEAN;

BEGIN
  -- nodatos = TRUE; 
   DELETE FROM facturaprestaciones  WHERE nroregistro= $1 AND anio=$2;
   DELETE FROM debitofacturaprestador  WHERE nroregistro= $1 AND anio=$2;
   --PERFORM imputacionauditoriamedica($1,$2);
   PERFORM buscarprestacionesordenfacturav1_buscaerror($1,$2);



INSERT INTO facturaprestaciones (anio,nroregistro,fidtipoprestacion,importe,debito) (
SELECT   $2 as anio,$1 as nroregistro , fidtipo as fidtipoprestacion, SUM(apagar) as importe, sum(impdebito) as debito
                         FROM (SELECT  SUM(importe)  AS apagar,   sum(case when nullvalue(facturaordenimputacion.importedebito) then 0 else 
                               facturaordenimputacion.importedebito  END) as impdebito, fidtipo 
                               FROM facturaordenimputacion_buscaerror as facturaordenimputacion JOIN factura USING(nroregistro, anio) 
                               WHERE nroregistro=$1 AND anio = $2
			       GROUP BY fidtipo 
                               UNION 
                               SELECT sum(importedebito) as apagar,sum(case when nullvalue(importedebito) then 0 else importedebito END ) as impdebito, fidtipo 
                               FROM facturadebitoimputacionpendiente JOIN ftipoprestacion ON (fidtipo=fidtipoprestacion) 
                               JOIN factura USING(nroregistro, anio) 
                               WHERE nroregistro=$1 AND anio = $2
                               GROUP BY fidtipo ) AS TT  
        	 	JOIN ftipoprestacion ON(TT.fidtipo=ftipoprestacion.fidtipoprestacion)   
                        GROUP BY fidtipo
);


 OPEN losdebitos FOR SELECT   $1 as nroregistro , $2 as anio , fidtipo  as fidtipoprestacion,SUM(importedebito) as debito,text_concatenar(motivo),idmotivodebitofacturacion::integer , nrocuentac 
                     FROM facturadebitoimputacion_buscaerror as facturadebitoimputacion JOIN factura USING(nroregistro, anio)  JOIN ftipoprestacion ON (fidtipo=fidtipoprestacion) 
                     WHERE nroregistro=$1 AND anio = $2 AND importedebito >0 
        	     GROUP BY idmotivodebitofacturacion, anio, nroregistro, fidtipo, nrocuentac;

    FETCH losdebitos INTO undebito;
    
    WHILE  found LOOP
              INSERT INTO debitofacturaprestador (anio,nroregistro,fidtipoprestacion,importe,observacion,idmotivodebitofacturacion)  
             VALUES(undebito.anio,undebito.nroregistro ,undebito.fidtipoprestacion,undebito.debito, '',undebito.idmotivodebitofacturacion);
             
       
            
             FETCH losdebitos INTO undebito;
          END LOOP;
   CLOSE losdebitos;
/*
IF nodatos THEN 
     PERFORM prestacionesfactura($1,$2);
END IF; 

*/
UPDATE factura SET fimportepagar = t.impapagar FROM (
                           select nroregistro,anio,sum(importe) - sum(CASE WHEN nullvalue(debito) THEN 0 ELSE debito END) as impapagar
                           from facturaprestaciones 
                           WHERE nroregistro = $1 AND anio = $2
                           GROUP BY nroregistro,anio) as t
                           WHERE t.nroregistro = factura.nroregistro
                           and t.anio = factura.anio;

SELECT INTO elresumen idresumen,anioresumen FROM factura WHERE not nullvalue(idresumen) and not nullvalue(anioresumen) and nroregistro=$1 and anio=$2;
IF FOUND THEN

       
       UPDATE factura set fimportepagar= (SELECT  SUM(fimportepagar) as apagar
                            FROM factura  WHERE idresumen=elresumen.idresumen AND anioresumen=elresumen.anioresumen  ) 
                            where nroregistro=elresumen.idresumen AND anio=elresumen.anioresumen;
END IF; 


--CAMBIO DE ESTADO AL REGISTRO
PERFORM cambiarestadosregistros($1,$2,1);

--genero el informe de amuc de auditoria para personas sin amuc
PERFORM generarinformeamuc();


   return true;
END;$function$
