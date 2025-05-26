CREATE OR REPLACE FUNCTION public.buscarprestacionesordenfacturav1(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

-- $1: nroregistro
-- $2: anio
  ccursordebito refcursor;
  rcomprobanteitem RECORD;

BEGIN
--creo la tabla temporal que tendra las cuentas contables sugeridas para la factura que se desea auditar

 IF NOT  iftableexistsparasp('facturaordenimputacion') THEN 
      CREATE TEMP TABLE facturaordenimputacion (
	    nroregistro integer,
	    anio integer,
	    prioridad integer,
	    nroorden bigint,
	    centro bigint,
	    fidtipo integer,
	    cuentac integer,
	    ftipoprestaciondesc character varying,
	    importe double precision,
	    importedebito double precision,
	    observacion character varying(100),
	    idmotivodebitofacturacion integer,
	    tipo bigint
	)WITHOUT OIDS;

   ELSE 
      DELETE FROM facturaordenimputacion; 
   END IF;

--KR antes era fisica 13-08-15DELETE FROM facturaordenimputacion WHERE nroregistro=$1 and anio=$2;

RAISE NOTICE 'Limpias las imputaciones (%)',CURRENT_TIMESTAMP;

INSERT INTO facturaordenimputacion (nroregistro,anio, prioridad,nroorden,centro, fidtipo,cuentac,ftipoprestaciondesc,importe,tipo)
 ( SELECT   $1 as nroregistro , $2 as anio ,Min(prioridad)as prioridad ,nroorden, centro,  fidtipo, cuentac,
		ftipoprestaciondesc, importe,tipo
FROM (
       select datoauditoria.idplancovertura, practica.idnomenclador ,
           practica.idcapitulo ,practica.idsubcapitulo, practica.idpractica ,
       case  when (
         mapeoctascontablesgastoventa.idplancobertura = datoauditoria.idplancovertura
         ) THEN 1
     when (
          practica.idnomenclador = mapeoctascontablesgastoventa.idnomenclador
          and practica.idcapitulo = mapeoctascontablesgastoventa.idcapitulo
          and practica.idsubcapitulo = mapeoctascontablesgastoventa.idsubcapitulo
          and practica.idpractica = mapeoctascontablesgastoventa.idpractica
     ) THEN 2
     when (
          practica.idnomenclador = mapeoctascontablesgastoventa.idnomenclador
          and  practica.idcapitulo = mapeoctascontablesgastoventa.idcapitulo
          and  practica.idsubcapitulo = mapeoctascontablesgastoventa.idsubcapitulo
          and  mapeoctascontablesgastoventa.idpractica ='**'
     ) THEN 3
     when(
          practica.idnomenclador = mapeoctascontablesgastoventa.idnomenclador
           and practica.idcapitulo = mapeoctascontablesgastoventa.idcapitulo
           and mapeoctascontablesgastoventa.idsubcapitulo = '**'
           and  mapeoctascontablesgastoventa.idpractica ='**'
           ) THEN 4
     when(
          practica.idnomenclador = mapeoctascontablesgastoventa.idnomenclador
          and    mapeoctascontablesgastoventa.idcapitulo = '**'
          and    mapeoctascontablesgastoventa.idsubcapitulo = '**'
          and   mapeoctascontablesgastoventa.idpractica ='**'
     ) THEN 5
     when (
          mapeoctascontablesgastoventa.nrocuentacventa = practica.nrocuentac
     ) THEN 6
     END as prioridad
     ,ftipoprestacion.fidtipoprestacion as fidtipo,ftipoprestacion.nrocuentac::integer as cuentac,
		ftipoprestacion.ftipoprestaciondesc,
ordenesutilizadas.importe  as importe,
--fmpaiimportetotal  as importe,
nroorden, centro, tipo
    from fichamedicapreauditada
    NATURAL JOIN parafichamedicapreauditada as datoauditoria
    NATURAL JOIN ordenesutilizadas
    NATURAL JOIN facturaordenesutilizadas
    NATURAL JOIN practica
    JOIN mapeoctascontablesgastoventa
    ON(
         (datoauditoria.idplancovertura = mapeoctascontablesgastoventa.idplancobertura
             OR  nullvalue( mapeoctascontablesgastoventa.idplancobertura ))
         and (practica.idnomenclador = mapeoctascontablesgastoventa.idnomenclador
                                or mapeoctascontablesgastoventa.idnomenclador ='**' )
         AND (practica.idcapitulo = mapeoctascontablesgastoventa.idcapitulo
                             or mapeoctascontablesgastoventa.idcapitulo ='**'  )
         AND (practica.idsubcapitulo = mapeoctascontablesgastoventa.idsubcapitulo
                                or mapeoctascontablesgastoventa.idsubcapitulo ='**' )
         AND (practica.idpractica = mapeoctascontablesgastoventa.idpractica
                             or mapeoctascontablesgastoventa.idpractica ='**'  )
         OR
          (practica.nrocuentac = mapeoctascontablesgastoventa.nrocuentacventa
           )
    )
    LEFT JOIN ftipoprestacion ON (ftipoprestacion.nrocuentac=mapeoctascontablesgastoventa.nrocuentacgasto)

    WHERE  nroregistro=$1 and anio=$2
)as T
group by  nroorden, centro,  fidtipo, cuentac, ftipoprestaciondesc, importe,nroorden, centro,tipo

)

;
RAISE NOTICE 'Cargadas las imputaciones (%)',CURRENT_TIMESTAMP;
DELETE FROM facturaordenimputacion
WHERE (prioridad, nroorden,centro,tipo,nroregistro,anio) IN
(
SELECT facturaordenimputacion.prioridad, nroorden,centro,tipo,nroregistro,anio
FROM facturaordenimputacion
LEFT JOIN (
  SELECT MIN(prioridad) as prioridad, nroorden,centro,tipo,nroregistro,anio
  FROM facturaordenimputacion
  group by nroorden,centro,tipo,nroregistro,anio
 having count(*)>1
 order by MIN(prioridad) ASC
 )as T using (nroorden,centro,tipo,nroregistro,anio)
WHERE  not  nullvalue(t.nroorden) and   nroregistro=$1 and anio=$2
AND t.prioridad <> facturaordenimputacion.prioridad
 );

RAISE NOTICE 'Me quedo solo con una prioridad';
/* Para recuperar los debitos que se hayan cargado a las ordenes*/
/*Malapi 16-07-2013 Modifico para que use la vista parafichamedicapreauditada
y que coloque el idmotivodebito
y que solo tome los debitos cuyos importes son mayores a cero */

OPEN ccursordebito FOR  SELECT R.fidtipo, R.cuentac,R.tipo, impdebito,nroregistro,anio, nroorden, centro,idmotivodebitofacturacion
                        FROM facturaordenesutilizadas
                        JOIN
                        (
                        SELECT nroorden,centro,tipo,fidtipo, facturaordenimputacion.cuentac,
                         min(fichamedicapreauditada.idmotivodebitofacturacion) as idmotivodebitofacturacion
                         , SUM(fmpaimportedebito) as impdebito
                        FROM  fichamedicapreauditada
                        NATURAL JOIN parafichamedicapreauditada
                        JOIN facturaordenimputacion
                        USING(nroorden, centro,tipo,nroregistro,anio)
                        WHERE facturaordenimputacion.nroregistro=$1 and facturaordenimputacion.anio=$2
                        and not nullvalue(fichamedicapreauditada.idmotivodebitofacturacion)
                        and fmpaimportedebito >  0
                        GROUP BY  nroorden,centro,tipo,fidtipo, cuentac
                        )as R USING (nroorden, centro,tipo)
                        WHERE nroregistro=$1 and anio=$2 and impdebito > 0;
                        
     FETCH ccursordebito into rcomprobanteitem;
     WHILE  found LOOP
                       UPDATE facturaordenimputacion SET importedebito =rcomprobanteitem.impdebito
                       ,idmotivodebitofacturacion =rcomprobanteitem.idmotivodebitofacturacion
                        WHERE facturaordenimputacion.nroregistro= rcomprobanteitem.nroregistro 
                        AND facturaordenimputacion.anio= rcomprobanteitem.anio 
                        AND facturaordenimputacion.fidtipo= rcomprobanteitem.fidtipo 
                        AND facturaordenimputacion.nroorden = rcomprobanteitem.nroorden
                        AND facturaordenimputacion.centro = rcomprobanteitem.centro 
                        AND facturaordenimputacion.tipo = rcomprobanteitem.tipo ;
                   
               fetch ccursordebito into rcomprobanteitem;
      END LOOP;

      close ccursordebito;

RAISE NOTICE 'Listos los debitos';


/* TODAS AQUELLAS ORDENES QUE FUERON UTILIZADAS POR AFILIADOS DE RECIPROCIDAD DEBEN IMPUTARSE
EN ESA CUENTA fidtipoprestacion = 10*/

UPDATE facturaordenimputacion
SET fidtipo =T.fidtipoprestacion, cuentac =nrocuentac::integer, ftipoprestaciondesc =T.ftipoprestaciondesc
FROM (
     SELECT *
     FROM ordenesutilizadas
     JOIN persona on (nrodoc = ordenesutilizadas.nrodocuso and tipodoc = ordenesutilizadas.tipodocuso)
     CROSS join ftipoprestacion
     WHERE barra > 100

) T
WHERE facturaordenimputacion.nroorden = T.nroorden
      and facturaordenimputacion.centro = T.centro
      and  facturaordenimputacion.tipo = T.tipo 
      and fidtipoprestacion = 10;




RAISE NOTICE 'Listos si es reciprocidad';


/*
Malapi 16-07-2013 Modifico para que use la vista parafichamedicapreauditada y que ademas no haga subqueris.
Queda comentado el original.
*/


/* Recuperar el iva */
INSERT INTO facturaordenimputacion (nroregistro,anio, prioridad,nroorden,centro, tipo,fidtipo,cuentac,ftipoprestaciondesc,importe)
SELECT nroregistro,anio,1,nroorden,centro, tipo,fidtipoprestacion
,nrocuentac::integer,ftipoprestaciondesc,fmpaiimporteiva as importe
       FROM  ftipoprestacion
       NATURAL JOIN parafichamedicapreauditada
       NATURAL JOIN fichamedicapreauditada
 WHERE fidtipoprestacion = 29 AND nroregistro=$1 and anio=$2 AND fmpaiimporteiva>0 AND NOT nullvalue(fmpaiimporteiva);
 
/*SELECT nroregistro,anio,1,nroorden,centro, tipo,fidtipoprestacion,nrocuentac::integer,ftipoprestaciondesc,importe
       FROM  ftipoprestacion
       NATURAL JOIN  facturaordenesutilizadas  NATURAL JOIN 
(SELECT fmpaiimporteiva as importe,29 as fidtipoprestacion,nroorden,centro,tipo
    FROM  fichamedicapreauditada
    NATURAL JOIN parafichamedicapreauditada
 WHERE fmpaiimporteiva<>0) AS R 
    WHERE nroregistro=$1 and anio=$2;*/

/*Malapi 17-06-2013 Modifico para que use la vista parafichamedicapreauditada
que use en el join en nroregistro y anio, ademas subo el where con el filtro del
nroderegistro y solo tomo los debitos con impebito > 0 . */

INSERT INTO facturadebitoimputacion (fidtipo,cuentac,ftipoprestaciondesc ,
           importedebito   ,
           nroregistro , 
           anio ,
           motivo ,
           idmotivodebitofacturacion)
      SELECT R.fidtipo, R.cuentac, R.ftipoprestaciondesc,
impdebito,nroregistro,anio,R.motivo,R.idmotivodebitofacturacion
FROM facturaordenesutilizadas
NATURAL JOIN
(SELECT nroorden,centro,tipo,fidtipo, facturaordenimputacion.cuentac ,ftipoprestaciondesc, fichamedicapreauditada.idmotivodebitofacturacion
,text_concatenar(fmpadescripciondebito) as motivo,SUM(fmpaimportedebito) as impdebito
    FROM  fichamedicapreauditada
    NATURAL JOIN parafichamedicapreauditada
   JOIN facturaordenimputacion USING(nroorden, centro,tipo,nroregistro,anio)
WHERE not nullvalue(fichamedicapreauditada.idmotivodebitofacturacion)
AND fmpaimportedebito > 0
AND nroregistro=$1 and anio=$2 and  fidtipo <> 29 
   GROUP BY  nroorden,centro,tipo,fidtipo, cuentac,ftipoprestaciondesc,fichamedicapreauditada.idmotivodebitofacturacion
 )as R
 WHERE nroregistro=$1 and anio=$2;

/*INSERTO los debitos realizados desde la aplicacion */

INSERT INTO facturadebitoimputacion(fidtipo, cuentac,  importedebito,nroregistro, anio ,motivo,idmotivodebitofacturacion) 
(SELECT fidtipo,  nrocuentacgasto,importedebito,nroregistro,anio,motivo,idmotivodebitofacturacion
FROM facturadebitoimputacionpendiente
WHERE  nroregistro=$1  and anio=$2 );





return true;
END;
$function$
