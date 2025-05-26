CREATE OR REPLACE FUNCTION public.spparareporterecibocaja(character varying, character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
 * PARAMETROS $1 fechadesde
 *            $2 fechahasta
 *            $3 centro
*/

DECLARE
	fechadesde alias for $1;
	fechahasta alias for $2;
	idcentro alias for $3;
        pfiltros alias for $3;
        rfiltros RECORD;

BEGIN

  EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

  idcentro = rfiltros.centro;

 
  CREATE TEMP TABLE tempreprecibo (
                  telefono VARCHAR
	         ,crdescripcion VARCHAR
                 ,direccioncentro VARCHAR
                 ,cregional VARCHAR
                 ,nroorden INTEGER
                 ,centro INTEGER
                 ,fechaemision VARCHAR
                 ,tipo INTEGER
                 ,nroAfiliado VARCHAR
                 ,anulado  VARCHAR
                 ,importe DOUBLE PRECISION
                 ,idformapagotipos INTEGER
                 ,tformapago VARCHAR
                 ,idrecibo BIGINT
                 ,idconcepto INTEGER
                 ,tcomprobante VARCHAR
                 ,cuentacorrienteconceptotipodescrip VARCHAR
                 ,oetdescripcion VARCHAR
            
            --     ,nrocuentac VARCHAR
                 ,reci VARCHAR      
, usuarionombre  VARCHAR 
,usuarioapellido  VARCHAR 
,idusuario bigint
);

/*Dani reemplazo el 21102022 donde decia conrec.idconepto por elidconcepto*/


INSERT INTO tempreprecibo
SELECT centroregional.telefono,
       centroregional.crdescripcion,
       concat(public.direccion.calle ,' ', public.direccion.nro) as direccioncentro,
       concat( centroregional.idcentroregional, ' - ' ,
       centroregional.crdescripcion , ' - ' , centroregional.crabreviatura) As CRegional,
       conrec.nroorden, conrec.centro, conrec.fechaemision, conrec.tipo, conrec.nroafiliado,
       anulado,
        conrec.importe, conrec.idformapagotipos, conrec.tformapago,
       conrec.idrecibo, conrec.elidconcepto
       ,concat(comprobantestipos.idcomprobantetipos, ' - ' , comprobantestipos.ctdescripcion) as tcomprobante
       ,ccct.cuentacorrienteconceptotipodescrip
       ,CASE WHEN nullvalue(conrec.oetdescripcion) THEN 'Emitida'
       ELSE conrec.oetdescripcion END as oetdescripcion
       
   --    ,conrec.nrocuentac
       ,conrec.reci
, usuarionombre
,usuarioapellido
,idusuario
FROM

/*se buscan los pagos de ordenes*/
(
SELECT  unionordenes.nroorden, unionordenes.centro, unionordenes.fechaemision, unionordenes.tipo,
          (concat(consumoafiliado.nrodoc , '-',  consumoafiliado.barra, ' ') )AS nroafiliado,
 CASE WHEN NOT NULLVALUE(reanulado) THEN 'Anulado' END AS anulado,
          CASE WHEN (nullvalue(unionordenes.oetdescripcion) and unionordenes.tipo <>55 and nullvalue(reanulado)) THEN io.importe * 1::double precision
             WHEN (not nullvalue(unionordenes.oetdescripcion) and unionordenes.tipo=  55 and nullvalue(reanulado)) THEN io.importe * 1::double precision
             ELSE io.importe * (- 1::double precision)   END AS importe, io.idformapagotipos,
          concat(formapagotipos.idformapagotipos, ' - ', formapagotipos.fpabreviatura) AS tformapago,
          r.idrecibo, 387 AS elidconcepto/*, CASE WHEN nullvalue(ttnrocuentac.nrocuentac) THEN '40311'
          ELSE ttnrocuentac.nrocuentac END as nrocuentac*/ ,
          /*CASE WHEN consumoafiliado.barra>= 100 and consumoafiliado.barra<> 131 and consumoafiliado.barra<> 149 THEN 'TRUE' ELSE 'FALSE' END as reci */

 CASE WHEN not nullvalue(consumoafiliado.barratitu) and consumoafiliado.barratitu>= 100 and  
          consumoafiliado.barratitu<> 131 and consumoafiliado.barratitu<> 149 THEN 'TRUE' ELSE 'FALSE' 
          END as reci ,unionordenes.oetdescripcion,usuario.nombre as usuarionombre, usuario.apellido as usuarioapellido,recibousuario.idusuario
FROM
 (         SELECT orden.nroorden, orden.centro, tipo, fechaemision, NULL::"unknown" AS oetdescripcion 
           FROM orden 
           UNION 
           (SELECT orden.nroorden, orden.centro, tipo, fechacambio as fechaemison, oetdescripcion
           FROM orden NATURAL JOIN  ordenestados NATURAL JOIN ordenestadotipos
)) 
 as unionordenes
/*LEFT JOIN  (SELECT nrocuentac, iv.nroorden, iv.centro
  FROM  itemvalorizada AS iv NATURAL JOIN item NATURAL JOIN practica
) AS ttnrocuentac ON (unionordenes.nroorden=ttnrocuentac.nroorden AND unionordenes.centro=ttnrocuentac.centro)
*/
  JOIN ordenrecibo ON (unionordenes.nroorden=ordenrecibo.nroorden AND unionordenes.centro=ordenrecibo.centro)
  JOIN recibo as r ON (ordenrecibo.idrecibo=r.idrecibo AND ordenrecibo.centro=r.centro)
join recibousuario on(r.idrecibo=recibousuario.idrecibo and r.centro= recibousuario.centro)
join usuario on(recibousuario.idusuario=usuario.idusuario)

  /*JOIN ( SELECT consumo.nroorden, consumo.centro, persona.nrodoc, persona.barra
                FROM consumo  NATURAL JOIN persona) */
JOIN ( SELECT consumo.nroorden, consumo.centro, persona.nrodoc, persona.barra, 
    case when nullvalue(benefreci.barratitu) then persona.barra 
    else benefreci.barratitu end as barratitu

          FROM consumo  NATURAL JOIN persona    left join benefreci 
          on (persona.nrodoc=benefreci.nrodoc and persona.tipodoc=benefreci.tipodoc and persona.barra>100)
      )consumoafiliado ON (unionordenes.nroorden= consumoafiliado.nroorden AND 
     unionordenes.centro=consumoafiliado.centro)

 JOIN importesorden as io ON (unionordenes.nroorden= io.nroorden AND unionordenes.centro=io.centro)
 NATURAL JOIN formapagotipos
 JOIN cajadiaria_configura_reportecaja ON (cajadiaria_configura_reportecaja.crcnombrefiltrointerface ilike rfiltros.crcnombrefiltrointerface AND unionordenes.tipo = cajadiaria_configura_reportecaja.crctipoorden )  
                           
 WHERE (unionordenes.fechaemision >=fechadesde AND unionordenes.fechaemision < fechahasta )
         and (idcentro=0 or unionordenes.centro = idcentro ) 
         and nullvalue(r.reanulado)
 
 UNION

/*se buscan los pagos de aportes*/
SELECT aporte.idaporte AS nroorden, aporte.idcentroregionaluso AS centro, recibo.fecharecibo AS fechaemision, 5 AS tipo,
 concat( datoslaborales.nrodoc , '-', datoslaborales.barra, ' ') AS nroafiliado,
  CASE WHEN NOT NULLVALUE(reanulado) THEN 'Anulado' END AS anulado
, case when (barra=35 or barra=36) then round(CAST( (aporte.impaporte + (aporte.impaporte * 0.105) )AS numeric),2)   else aporte.impaporte end
  AS importe
, importesrecibo.idformapagotipos,
 concat(formapagotipos.idformapagotipos, ' - ' , formapagotipos.fpabreviatura) AS tformapago
, recibo.idrecibo, 200 AS elidconcepto--,cuentascontables.nrocuentac
 ,CASE WHEN datoslaborales.barra>= 100 THEN 'TRUE'
          ELSE 'FALSE' END as reci, '' AS oetdescripcion,usuario.nombre as usuarionombre, usuario.apellido as usuarioapellido,recibousuario.idusuario
FROM recibo NATURAL JOIN importesrecibo 
join recibousuario on(recibo.idrecibo=recibousuario.idrecibo and recibo.centro= recibousuario.centro)
join usuario on(recibousuario.idusuario=usuario.idusuario)

NATURAL JOIN formapagotipos
JOIN ( SELECT aporte.idaporte, aporte.mes, aporte.ano, aporte.idcentroregionaluso, aporte.idlaboral, aporte.idrecibo,aporte.idcargo, aporte.idcertpers, aporte.fechaingreso, aporte.importe AS impaporte--, aporte.nrocuentac
   FROM aporte) aporte ON (recibo.centro = aporte.idcentroregionaluso AND recibo.idrecibo = aporte.idrecibo)
  JOIN
   (SELECT nrodoc, barra, tipodoc, datosper.idlaboral
    FROM
    (SELECT nrodoc, tipodoc, idcertpers AS idlaboral,barra
     FROM afiljub
     JOIN persona USING(nrodoc, tipodoc)
     WHERE (barra = 35 )
     UNION
     SELECT nrodoc, tipodoc, idcert AS idlaboral,barra
     FROM afilpen
     JOIN persona USING(nrodoc, tipodoc)
     WHERE (barra = 36)
     UNION
     SELECT nrodoc, tipodoc, idcargo AS idlaboral,barra
     FROM cargo
     JOIN persona USING(nrodoc, tipodoc)
     WHERE (barra <> 35 AND barra <> 36) 
) as datosper)
     datoslaborales USING(idlaboral) NATURAL JOIN cuentascontables
     WHERE (recibo.fecharecibo >=fechadesde AND recibo.fecharecibo < fechahasta)
           and (idcentro=0 or recibo.centro = idcentro )
           and rfiltros.crcnombrefiltrointerface not ilike 'NO afecta Caja' 
and nullvalue(recibo.reanulado)
/*se buscan los pagos de clientes*/
/*03-09-2014 Malapi No se necesita en en reporte de recibo la información de recibos automaticos por descuento
por planilla. Solo es necesario lo que afecta la caja.*/

    UNION
      SELECT  CASE when nullvalue(ccp.idcomprobante) then ccpna.idcomprobante  ELSE ccp.idcomprobante END AS nroorden, 
      r.centro, r.fecharecibo AS fechaemision,
        mccct.idcomprobantetipos AS tipo
,concat(  (concat(CASE when nullvalue(ccp.nrodoc) then ccpna.nrodoc else ccp.nrodoc  END::text , '-'::text)) ,
 btrim(to_char(CASE when nullvalue(ccp.tipodoc) then ccpna.tipodoc else ccp.tipodoc END::double precision, '999'::text))) AS nroafiliado, 
 CASE WHEN NOT NULLVALUE(reanulado) THEN 'Anulado' END AS anulado, 
 
 -- importesrecibo.importe, 
   CASE WHEN ( nullvalue(reanulado)) THEN importesrecibo.importe
             
             ELSE importesrecibo.importe * (- 1::double precision)   END AS importe, 
             importesrecibo.idformapagotipos

 ,concat( formapagotipos.idformapagotipos,  ' - ', formapagotipos.fpabreviatura) AS tformapago, r.idrecibo,
CASE when nullvalue(ccp.idconcepto) then ccpna.idconcepto ELSE ccp.idconcepto END as elidconcepto
--, CASE when nullvalue(ccp.nrocuentac) then ccpna.nrocuentac  ELSE ccp.nrocuentac  END
,CASE WHEN CASE when nullvalue(ccp.tipodoc) then ccpna.tipodoc  else ccp.tipodoc END>= 100 THEN 'TRUE' ELSE 'FALSE' END as reci
, '' AS oetdescripcion,usuario.nombre as usuarionombre, usuario.apellido as usuarioapellido,recibousuario.idusuario

 FROM recibo as r NATURAL JOIN importesrecibo 
join recibousuario on(r.idrecibo=recibousuario.idrecibo and r.centro= recibousuario.centro)
join usuario on(recibousuario.idusuario=usuario.idusuario)

NATURAL JOIN formapagotipos
 LEFT JOIN cuentacorrientepagos as ccp ON (r.idrecibo = ccp.idcomprobante AND r.centro=ccp.idcentropago AND ccp.idcomprobantetipos = 0)	
 LEFT JOIN ctactepagonoafil as ccpna ON (r.idrecibo = ccpna.idcomprobante AND r.centro=ccpna.idcentropago AND ccpna.idcomprobantetipos = 0)	
 JOIN mapeocuentascontablescomprobantestipos  AS mccct ON 
(CASE when nullvalue(ccp.nrocuentac) then ccpna.nrocuentac else ccp.nrocuentac END = mccct.nrocuentac)
WHERE ( not nullvalue(ccp.idpago) OR not nullvalue(ccpna.idpago) ) AND (r.fecharecibo >=fechadesde AND r.fecharecibo < fechahasta )
      and (idcentro=0 or r.centro = idcentro )
      and  formapagotipos.idformapagotipos <> 13
      and rfiltros.crcnombrefiltrointerface not ilike 'NO afecta Caja' 
      and nullvalue(r.reanulado)
) AS conrec  JOIN centroregional ON (centroregional.idcentroregional = conrec.centro)
JOIN direccion ON(centroregional.iddireccion=direccion.iddireccion /*AND centroregional.idcentroregional=direccion.idcentrodireccion*/)
JOIN comprobantestipos ON (comprobantestipos.idcomprobantetipos = conrec.tipo)
/*JOIN cuentacorrienteconceptotipo as ccct ON(ccct.idconcepto=conrec.idconcepto; */

JOIN cuentacorrienteconceptotipo as ccct ON(ccct.idconcepto=conrec.elidconcepto AND (CASE WHEN conrec.elidconcepto =360 THEN idprestamotipos =1 ELSE TRUE END));


return true;
END;$function$
