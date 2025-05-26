CREATE OR REPLACE FUNCTION public.imputacionauditoriamedica(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Calcula los valores de la practica segun la configuracion establecida
en la tabla practconvval*/

DECLARE
    resp boolean;
    unresumen record;
	losresumenes refcursor;
	esfactura boolean;
	
BEGIN

   IF NOT  iftableexistsparasp('tempprestacion') THEN 
       CREATE  TEMP TABLE tempprestacion(
           tipoprestacion integer,
           nrocuentagto integer,
           descnrocuentagto varchar,
           importe DOUBLE PRECISION,
           importedebito DOUBLE PRECISION DEFAULT 0,
           observacion varchar,
           idmotivodebitofacturacion varchar
       ) WITHOUT OIDS;
   ELSE 
      DELETE FROM tempprestacion; 
   END IF;
   IF NOT  iftableexists('facturadebitoimputacion') THEN 
      CREATE TEMP  TABLE facturadebitoimputacion(
           fidtipo integer,
           cuentac varchar,
           ftipoprestaciondesc varchar,
           importedebito DOUBLE PRECISION ,
           nroregistro integer,
           anio integer,
           motivo varchar,
           idmotivodebitofacturacion integer
    ) WITHOUT OIDS;
  ELSE 
      DELETE FROM facturadebitoimputacion; 
  END IF;
   esfactura = true;
   OPEN losresumenes FOR SELECT * FROM factura WHERE  idresumen =$1  and anioresumen=$2;
   FETCH losresumenes INTO unresumen;
   WHILE  found LOOP
             esfactura = false;
             SELECT INTO resp   buscarprestacionesordenfacturav1(unresumen.nroregistro,unresumen.anio);
             FETCH losresumenes INTO unresumen;
    END LOOP;
    CLOSE losresumenes;


    If esfactura THEN
          SELECT INTO resp   buscarprestacionesordenfacturav1($1,$2);
    END IF;

    
    return resp;
END;
$function$
