CREATE OR REPLACE FUNCTION public.guardarprestacionesfactura(integer, integer, boolean)
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

  
   esfactura = true;
   SELECT INTO esresumen * FROM factura WHERE  idresumen =$1  and anioresumen=$2;
   IF FOUND THEN
       esfactura = false;
      IF  $3 THEN
          PERFORM prestacionesresumensugeridas($1,$2);
      ELSE
    
          OPEN losresumenes FOR SELECT * FROM factura WHERE  idresumen =$1  and anioresumen=$2;
          FETCH losresumenes INTO unresumen;
          WHILE  found LOOP
             esfactura = false;
             SELECT INTO resp prestacionesfactura(unresumen.nroregistro,unresumen.anio);
            
             FETCH losresumenes INTO unresumen;
          END LOOP;
          CLOSE losresumenes;
      END IF;
   END IF;
    
  If esfactura THEN
          SELECT INTO resp prestacionesfactura($1,$2);
    END IF;

   IF not esfactura THEN
        /*  SELECT INTO importetotalapagar fimportepagar FROM factura  WHERE idresumen =$1  and anioresumen=$2;
          UPDATE factura set fimportepagar = importetotalapagar WHERE nroregistro =$1  and anio=$2;
            Malapi 22-11-2012 Modifico para que saque el importe a pagar de las sumas y restas de las imputaciones 
         */
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
    ELSE 
         UPDATE factura SET fimportepagar = t.impapagar FROM (
                           select nroregistro,anio,sum(importe) - sum(CASE WHEN nullvalue(debito) THEN 0 ELSE debito END) as impapagar
                           from facturaprestaciones 
                           WHERE nroregistro = $1 AND anio = $2
                           GROUP BY nroregistro,anio) as t
                           WHERE t.nroregistro = factura.nroregistro
                           and t.anio = factura.anio;
 
    END IF;

  
    return true;
END;
$function$
