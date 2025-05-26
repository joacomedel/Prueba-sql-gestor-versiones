CREATE OR REPLACE FUNCTION public.buscarprestacionesordenfactura(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

-- $1: nroregistro
-- $2: anio
ccursordebito refcursor;
--cursor con los datos que se deben cargar en la tabla del nuevo informe
--ordenfac CURSOR FOR SELECT nroorden,centro FROM facturaordenesutilizadas WHERE nroregistro=$1 and anio=$2;
--regordenfac RECORD;
  rcomprobanteitem record;

BEGIN
--creo la tabla temporal que tendra las cuentas contables sugeridas para la factura que se desea auditar

CREATE TEMP TABLE facturadebitoimputacion(
           fidtipo integer,
           cuentac varchar,
           ftipoprestaciondesc varchar,
           importedebito DOUBLE PRECISION ,
           nroregistro integer,
           anio integer,
           motivo varchar,
           idmotivodebitofacturacion integer
    ) WITHOUT OIDS;

DELETE FROM facturaordenimputacion WHERE nroregistro=$1 and anio=$2;
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
    NATURAL JOIN (
           SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada,idplancovertura
            FROM  fichamedicapreauditadaitemconsulta
            NATURAL JOIN ordconsulta
            UNION
            SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada,idplancovertura
            FROM fichamedicapreauditadaitem
            NATURAL JOIN itemvalorizada
            UNION
            SELECT nrorecetario as nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada,idplancovertura
            FROM fichamedicapreauditadaitemrecetario 
            NATURAL JOIN recetarioitem NATURAL JOIN recetario
   ) as datoauditoria
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

/* Para recuperar los debitos que se hayan cargado a las ordenes*/


OPEN ccursordebito FOR  SELECT R.fidtipo, R.cuentac,R.tipo, impdebito,nroregistro,anio, nroorden, centro
FROM facturaordenesutilizadas
 JOIN
(SELECT nroorden,centro,tipo,fidtipo, facturaordenimputacion.cuentac , SUM(fmpaimportedebito) as impdebito
    FROM  fichamedicapreauditada
    NATURAL JOIN (
            SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada
            FROM  fichamedicapreauditadaitemconsulta
            UNION
            SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada
            FROM fichamedicapreauditadaitem
            NATURAL JOIN itemvalorizada
            UNION
            SELECT nrorecetario as nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada
            FROM fichamedicapreauditadaitemrecetario 
            NATURAL JOIN recetarioitem 
    ) as T
   JOIN facturaordenimputacion USING(nroorden, centro,tipo)
   WHERE not nullvalue(fichamedicapreauditada.idmotivodebitofacturacion)
   GROUP BY  nroorden,centro,tipo,fidtipo, cuentac
 )as R USING (nroorden, centro,tipo)
 WHERE nroregistro=$1 and anio=$2;
     FETCH ccursordebito into rcomprobanteitem;
     WHILE  found LOOP
                          
 
UPDATE facturaordenimputacion SET importedebito =rcomprobanteitem.impdebito

WHERE facturaordenimputacion.nroregistro= rcomprobanteitem.nroregistro 
AND  facturaordenimputacion.anio= rcomprobanteitem.anio
AND  facturaordenimputacion.fidtipo= rcomprobanteitem.fidtipo
and  facturaordenimputacion.nroorden = rcomprobanteitem.nroorden
and  facturaordenimputacion.centro = rcomprobanteitem.centro 
and  facturaordenimputacion.tipo = rcomprobanteitem.tipo ;
                   
                   fetch ccursordebito into rcomprobanteitem;
      END LOOP;

      close ccursordebito;




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










/* Recuperar el iva */
INSERT INTO facturaordenimputacion (nroregistro,anio, prioridad,nroorden,centro, tipo,fidtipo,cuentac,ftipoprestaciondesc,importe)
/*(
       SELECT nroregistro,anio,1,nroorden,centro,tipo, fidtipoprestacion,nrocuentac::integer,ftipoprestaciondesc,importe
       FROM  ftipoprestacion
       NATURAL JOIN  (
               select fmpaiimporteiva as importe,29 as fidtipoprestacion,nroorden,centro,tipo,nroregistro,anio
               from facturaordenesutilizadas
               natural join fichamedicapreauditada
               natural join fichamedicapreauditadaitem
               NATURAL JOIN itemvalorizada
               WHERE nroregistro=$1 and anio=$2 AND fmpaiimporteiva<>0
       ) as t
);
*/
SELECT nroregistro,anio,1,nroorden,centro, tipo,fidtipoprestacion,nrocuentac::integer,ftipoprestaciondesc,importe
       FROM  ftipoprestacion
       NATURAL JOIN  facturaordenesutilizadas  NATURAL JOIN 
(SELECT fmpaiimporteiva as importe,29 as fidtipoprestacion,nroorden,centro
    FROM  fichamedicapreauditada
    NATURAL JOIN (
            SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada
            FROM  fichamedicapreauditadaitemconsulta
            UNION
            SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada
            FROM fichamedicapreauditadaitem
            NATURAL JOIN itemvalorizada 
             UNION
            SELECT nrorecetario as nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada
            FROM fichamedicapreauditadaitemrecetario 
            NATURAL JOIN recetarioitem ) as T 
 WHERE fmpaiimporteiva<>0) AS R 
    WHERE nroregistro=$1 and anio=$2;



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
(SELECT nroorden,centro,tipo,fidtipo, facturaordenimputacion.cuentac ,ftipoprestaciondesc, fichamedicapreauditada.idmotivodebitofacturacion,text_concatenar(fmpadescripciondebito) as motivo,SUM(fmpaimportedebito) as impdebito
    FROM  fichamedicapreauditada
    NATURAL JOIN (
            SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada
            FROM  fichamedicapreauditadaitemconsulta
            UNION
            SELECT nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada
            FROM fichamedicapreauditadaitem
            NATURAL JOIN itemvalorizada
            UNION
            SELECT nrorecetario as nroorden,centro,idfichamedicapreauditada, idcentrofichamedicapreauditada
            FROM fichamedicapreauditadaitemrecetario 
            NATURAL JOIN recetarioitem 
    ) as T
   JOIN facturaordenimputacion USING(nroorden, centro,tipo)
WHERE not nullvalue(fichamedicapreauditada.idmotivodebitofacturacion)
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
