CREATE OR REPLACE FUNCTION public.guardarprestacionesfactura(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--CURSORES
losresumenes refcursor;

--REGISTRO
unresumen record;
esresumen record;
perteneceresumen record; 

--VARIABLES
esfactura boolean;
resp boolean;

BEGIN

  
   esfactura = true;
   SELECT INTO esresumen * FROM factura WHERE  idresumen =$1  and anioresumen=$2;
   IF FOUND THEN
       esfactura = false;
      
          OPEN losresumenes FOR SELECT * FROM factura WHERE  idresumen =$1  and anioresumen=$2;
          FETCH losresumenes INTO unresumen;
          WHILE  found LOOP
      
             SELECT INTO resp prestacionesfactura(unresumen.nroregistro,unresumen.anio);
            
             FETCH losresumenes INTO unresumen;
          END LOOP;
          CLOSE losresumenes;
     
         UPDATE factura SET fimportepagar = t.impapagar FROM (
                           SELECT nroregistro,anio,sum(importe) - sum(CASE WHEN nullvalue(debito) THEN 0 ELSE debito END) as impapagar
                            FROM facturaprestaciones NATURAL JOIN factura
                           WHERE idresumen = $1 AND anioresumen = $2
                           GROUP BY nroregistro,anio) as t
                           WHERE t.nroregistro = factura.nroregistro
                           and t.anio = factura.anio;

              UPDATE factura set fimportepagar= (SELECT  SUM(fimportepagar) as apagar
                            FROM factura  WHERE idresumen=$1 AND anioresumen=$2   ) 
                            where nroregistro=$1 AND anio=$2;
   END IF;
    
  If esfactura THEN
          SELECT INTO resp prestacionesfactura($1,$2);
         /* UPDATE factura SET fimportepagar = t.impapagar FROM (
                           select nroregistro,anio,sum(importe) - sum(CASE WHEN nullvalue(debito) THEN 0 ELSE debito END) as impapagar
                           from facturaprestaciones 
                           WHERE nroregistro = $1 AND anio = $2
                           GROUP BY nroregistro,anio) as t
                           WHERE t.nroregistro = factura.nroregistro
                           and t.anio = factura.anio;*/

         SELECT INTO perteneceresumen * FROM factura WHERE nroregistro=$1 AND anio=$2; 
         IF FOUND THEN 
                  UPDATE factura set fimportepagar= (SELECT  SUM(fimportepagar) as apagar
                            FROM factura  WHERE idresumen=perteneceresumen.idresumen AND anioresumen=perteneceresumen.anioresumen   ) 
                            where nroregistro=perteneceresumen.idresumen AND anio=perteneceresumen.anioresumen;
         END IF; 
 
    END IF;

 
    return true;
END;
$function$
