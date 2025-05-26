CREATE OR REPLACE FUNCTION public.buscarprestacionesordenfacturav1_buscaerror(integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

-- $1: nroregistro
-- $2: anio
  ccursordebito refcursor;
  rcomprobanteitem RECORD;

BEGIN
--creo la tabla temporal que tendra las cuentas contables sugeridas para la factura que se desea auditar

 IF NOT  iftableexistsparasp('facturaordenimputacion_buscaerror') THEN 
      CREATE TEMP TABLE facturaordenimputacion_buscaerror (
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
	    txtmotivodebito text,
	    tipo bigint,
	    txtfichamedicapreauditada text
	)WITHOUT OIDS;

   ELSE 
      DELETE FROM facturaordenimputacion_buscaerror; 
   END IF;

 IF NOT  iftableexists('facturadebitoimputacion_buscaerror') THEN 
      CREATE TEMP  TABLE facturadebitoimputacion_buscaerror(
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

--KR antes era fisica 13-08-15DELETE FROM facturaordenimputacion_buscaerror WHERE nroregistro=$1 and anio=$2;


RAISE NOTICE 'Limpias las imputaciones (%)',CURRENT_TIMESTAMP;

INSERT INTO facturaordenimputacion_buscaerror (nroregistro,anio, prioridad,nroorden,centro, fidtipo,cuentac,ftipoprestaciondesc,importe,tipo,txtfichamedicapreauditada)
 ( SELECT   $1 as nroregistro , $2 as anio ,Min(prioridad)as prioridad ,nroorden, centro,  fidtipo, cuentac,
		ftipoprestaciondesc, importe,tipo,text_concatenarsinrepetir(concat('<',idfichamedicapreauditada,'-',idcentrofichamedicapreauditada,'>|')) as txtfichamedicapreauditada
FROM (
       select datoauditoria.idplancovertura, practica.idnomenclador ,
           practica.idcapitulo ,practica.idsubcapitulo, practica.idpractica ,
       case  when (
--MaLaPi 17-08-2021 Agrego para que no tome una configuracion por plan, si el plan se trata del general... pues no es un caso especial que deba tener en cuenta
         mapeoctascontablesgastoventa.idplancobertura = datoauditoria.idplancovertura AND mapeoctascontablesgastoventa.idplancobertura <> 1
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
     -- MaLaPi 17-08-2021 Me aseguro que si va a tomar la configuracion por cta de venta, no haya nada mas configurado en el mapeo... sino las otras son mas fuertes
          mapeoctascontablesgastoventa.nrocuentacventa = practica.nrocuentac AND mapeoctascontablesgastoventa.idnomenclador = '**'
     ) THEN 6
     --MaLapi 18-08-2021 Le agrego la minima priodidad cuando no machea con ninguna de las anteriores.
     ELSE 7
     END as prioridad
     ,ftipoprestacion.fidtipoprestacion as fidtipo,ftipoprestacion.nrocuentac::integer as cuentac,
		ftipoprestacion.ftipoprestaciondesc,
--MaLaPi 30-07-2019 Cambio el importe para que sea tomado a nivel de item
--ordenesutilizadas.importe  as importe,
fmpaiimportes  as importe,
nroorden, centro, tipo,idfichamedicapreauditada,idcentrofichamedicapreauditada
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
group by  nroorden, centro,  fidtipo, cuentac, ftipoprestaciondesc, importe
--MaLaPi 02-12-2019 Me fume algo y le agregue esto, me funca para el nroregistro 155532
--MaLApi 02-12-2019 El agrupador, pierde tuplas cuando tiene, igual importe, igual pruiridad y cuenta pero se trata de items de auditoria distitnos (idfichamedicapreauditada)
,concat('<',idfichamedicapreauditada,'-',idcentrofichamedicapreauditada,'>|')
,tipo

)

;
RAISE NOTICE 'Cargadas las imputaciones (%)',CURRENT_TIMESTAMP;
DELETE FROM facturaordenimputacion_buscaerror
WHERE (prioridad, nroorden,centro,tipo,nroregistro,anio,txtfichamedicapreauditada,importe) IN
(
SELECT facturaordenimputacion_buscaerror.prioridad, nroorden,centro,tipo,nroregistro,anio,txtfichamedicapreauditada,importe
FROM facturaordenimputacion_buscaerror
LEFT JOIN (
-- 04-08-2021 MaLaPi agrego en la selecciona txtfichamedicapreauditada, pues puede haber casos donde las practicas son distintas y tienen el mismo importe
  SELECT MIN(prioridad) as prioridad, nroorden,centro,tipo,nroregistro,anio,importe,txtfichamedicapreauditada
  FROM facturaordenimputacion_buscaerror
  group by nroorden,centro,tipo,nroregistro,anio,importe,txtfichamedicapreauditada
 having count(*)>1
 order by MIN(prioridad) ASC
 )as T using (nroorden,centro,tipo,nroregistro,anio,importe,txtfichamedicapreauditada)
WHERE  not  nullvalue(t.nroorden) and   nroregistro=$1 and anio=$2
AND t.prioridad <> facturaordenimputacion_buscaerror.prioridad
--02-12-19 Malapi para resolver la no eliminacion de prestaciones con diferentes cuentas contables aplicadas a distintos idfichamedicacontable
 and  trim(split_part(txtfichamedicapreauditada, '|',2))=''

 );

RAISE NOTICE 'Me quedo solo con una prioridad';
/* Para recuperar los debitos que se hayan cargado a las ordenes*/
/*Malapi 16-07-2013 Modifico para que use la vista parafichamedicapreauditada
y que coloque el idmotivodebito
y que solo tome los debitos cuyos importes son mayores a cero 
MaLaPi 30-07-2019 Cambio la forma de recuperar los debitos, uso la fichamedicapreauditada 
*/

OPEN ccursordebito FOR  
			SELECT t.nroregistro,t.anio,txtfichamedicapreauditada,t.nroorden,t.centro,t.tipo,t.fidtipo,t.cuentac
			,min(fmpa.idmotivodebitofacturacion) as idmotivodebitofacturacion
			, sum(fmpa.fmpaimportedebito) as impdebito
                        , text_concatenarsinrepetir(concat(fmpadescripciondebito,' ')) as txtmotivodebito
                        FROM  fichamedicapreauditada as fmpa
                        NATURAL JOIN parafichamedicapreauditada as pfmpa
                        JOIN facturaordenimputacion_buscaerror as t
				ON t.nroorden = pfmpa.nroorden AND t.centro = pfmpa.centro AND t.tipo = pfmpa.tipo AND  t.nroregistro = pfmpa.nroregistro 
				AND t.anio = pfmpa.anio AND txtfichamedicapreauditada ilike concat('%<',idfichamedicapreauditada,'-',idcentrofichamedicapreauditada,'>|%')
                        WHERE  t.nroregistro=$1 and t.anio=$2 
                        and not nullvalue(fmpa.idmotivodebitofacturacion)
                        and fmpaimportedebito >  0 
                        GROUP BY  t.nroregistro,t.anio,txtfichamedicapreauditada,t.nroorden,t.centro,t.tipo,t.fidtipo,t.cuentac;
                        
     FETCH ccursordebito into rcomprobanteitem;
     WHILE  found LOOP
                       UPDATE facturaordenimputacion_buscaerror SET importedebito =rcomprobanteitem.impdebito
                       ,idmotivodebitofacturacion =rcomprobanteitem.idmotivodebitofacturacion, txtmotivodebito = rcomprobanteitem.txtmotivodebito
                        WHERE facturaordenimputacion_buscaerror.nroregistro= rcomprobanteitem.nroregistro 
                        AND facturaordenimputacion_buscaerror.anio= rcomprobanteitem.anio 
                        AND facturaordenimputacion_buscaerror.fidtipo= rcomprobanteitem.fidtipo 
                        AND facturaordenimputacion_buscaerror.nroorden = rcomprobanteitem.nroorden
                        AND facturaordenimputacion_buscaerror.centro = rcomprobanteitem.centro 
                        AND facturaordenimputacion_buscaerror.tipo = rcomprobanteitem.tipo 
                        AND facturaordenimputacion_buscaerror.cuentac = rcomprobanteitem.cuentac
                        AND facturaordenimputacion_buscaerror.txtfichamedicapreauditada = rcomprobanteitem.txtfichamedicapreauditada ;
                   
               fetch ccursordebito into rcomprobanteitem;
      END LOOP;

      close ccursordebito;

RAISE NOTICE 'Listos los debitos';

/* TODAS AQUELLAS ORDENES QUE FUERON UTILIZADAS POR AFILIADOS DE RECIPROCIDAD DEBEN IMPUTARSE
EN ESA CUENTA fidtipoprestacion = 10*/

UPDATE facturaordenimputacion_buscaerror
SET fidtipo =T.fidtipoprestacion, cuentac =nrocuentac::integer, ftipoprestaciondesc =T.ftipoprestaciondesc
FROM (
     SELECT *
     FROM ordenesutilizadas
     JOIN persona on (nrodoc = ordenesutilizadas.nrodocuso and tipodoc = ordenesutilizadas.tipodocuso)
     CROSS join ftipoprestacion
     WHERE barra > 100

) T
WHERE facturaordenimputacion_buscaerror.nroorden = T.nroorden
      and facturaordenimputacion_buscaerror.centro = T.centro
      and  facturaordenimputacion_buscaerror.tipo = T.tipo 
      and fidtipoprestacion = 10;




RAISE NOTICE 'Listos si es reciprocidad';


/*
Malapi 16-07-2013 Modifico para que use la vista parafichamedicapreauditada y que ademas no haga subqueris.
Queda comentado el original.
*/


/* Recuperar el iva */
INSERT INTO facturaordenimputacion_buscaerror (nroregistro,anio, prioridad,nroorden,centro, tipo,fidtipo,cuentac,ftipoprestaciondesc,importe)
SELECT nroregistro,anio,1,nroorden,centro, tipo,fidtipoprestacion
,nrocuentac::integer,ftipoprestaciondesc,fmpaiimporteiva as importe
       FROM  ftipoprestacion
       NATURAL JOIN parafichamedicapreauditada
       NATURAL JOIN fichamedicapreauditada
 WHERE fidtipoprestacion = 29 AND nroregistro=$1 and anio=$2 AND fmpaiimporteiva>0 AND NOT nullvalue(fmpaiimporteiva);
 

/*Malapi 17-06-2013 Modifico para que use la vista parafichamedicapreauditada
que use en el join en nroregistro y anio, ademas subo el where con el filtro del
nroderegistro y solo tomo los debitos con impebito > 0 . 

MaLapi 30-07-2019 Cambio la forma de completar los motivos de debitos en la tabla facturadebitoimputacion
*/
/*
INSERT INTO facturadebitoimputacion (fidtipo,cuentac,ftipoprestaciondesc ,importedebito   ,nroregistro , anio , motivo ,idmotivodebitofacturacion)
      SELECT R.fidtipo, R.cuentac, R.ftipoprestaciondesc, impdebito,nroregistro,anio,R.motivo,R.idmotivodebitofacturacion
FROM facturaordenesutilizadas
NATURAL JOIN
(SELECT nroorden,centro,tipo,fidtipo, facturaordenimputacion.cuentac ,ftipoprestaciondesc, fichamedicapreauditada.idmotivodebitofacturacion
,text_concatenar(fmpadescripciondebito) as motivo,SUM(fmpaimportedebito) as impdebito
    FROM  fichamedicapreauditada as fmpa
    NATURAL JOIN parafichamedicapreauditada as pfmpa
   JOIN facturaordenimputacion_buscaerror as t ON t.nroorden = pfmpa.nroorden AND t.centro = pfmpa.centro AND t.tipo = pfmpa.tipo AND  t.nroregistro = pfmpa.nroregistro 
				AND t.anio = pfmpa.anio AND txtfichamedicapreauditada ilike concat('%<',idfichamedicapreauditada,'-',idcentrofichamedicapreauditada,'>|%')
WHERE not nullvalue(fmpa.idmotivodebitofacturacion)
AND fmpaimportedebito > 0
AND nroregistro=$1 and anio=$2 and  fidtipo <> 29 
   GROUP BY  nroorden,centro,tipo,fidtipo, cuentac,ftipoprestaciondesc,fmpa.idmotivodebitofacturacion
 )as R
 WHERE nroregistro=$1 and anio=$2;
*/
INSERT INTO facturadebitoimputacion_buscaerror (fidtipo,cuentac,ftipoprestaciondesc ,importedebito   ,nroregistro , anio , motivo ,idmotivodebitofacturacion)
(
SELECT  fidtipo,cuentac,ftipoprestaciondesc,sum(importedebito) as importedebito,nroregistro,anio,text_concatenarsinrepetir(txtmotivodebito) as motivo,idmotivodebitofacturacion
FROM facturaordenimputacion_buscaerror
WHERE not nullvalue(txtmotivodebito)
AND importedebito > 0
AND nroregistro=$1 and anio=$2 and  fidtipo <> 29 
 GROUP BY  nroregistro,anio,nroorden,centro,tipo,fidtipo, cuentac,ftipoprestaciondesc,idmotivodebitofacturacion
);
--INSERTO los debitos realizados desde la aplicacion 

INSERT INTO facturadebitoimputacion_buscaerror(fidtipo, cuentac,  importedebito,nroregistro, anio ,motivo,idmotivodebitofacturacion) 
(SELECT fidtipo,  nrocuentacgasto,importedebito,nroregistro,anio,motivo,idmotivodebitofacturacion
FROM facturadebitoimputacionpendiente
WHERE  nroregistro=$1  and anio=$2 );




return true;
END;
$function$
