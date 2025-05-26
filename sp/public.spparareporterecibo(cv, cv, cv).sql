CREATE OR REPLACE FUNCTION public.spparareporterecibo(character varying, character varying, character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
*  Permite mostrar los recibos de clientes, se asume que en el modulo de tesoreria no se necesita ver la informacion de los
*  recibos de ordenes ni los aportes que no sean de la unc. 
 * PARAMETROS $1 fechadesde
 *            $2 fechahasta
 *            $3 centro
*/

DECLARE
	fechadesde alias for $1;
	fechahasta alias for $2;
	idcentro alias for $3;

BEGIN

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
                 ,importe DOUBLE PRECISION
                 ,idformapagotipos INTEGER
                 ,tformapago VARCHAR
                 ,idrecibo BIGINT
                 ,idconcepto INTEGER
                 ,tcomprobante VARCHAR
                 ,cuentacorrienteconceptotipodescrip VARCHAR
                 ,oetdescripcion VARCHAR
            
                 ,nrocuentac VARCHAR
                 ,reci VARCHAR      );

INSERT INTO tempreprecibo
SELECT centroregional.telefono,
       centroregional.crdescripcion,
       concat(public.direccion.calle ,' ', public.direccion.nro) as direccioncentro,
       concat(to_char(centroregional.idcentroregional,'99') , ' - ' ,
       centroregional.crdescripcion , ' - ' , centroregional.crabreviatura) As CRegional,
       conrec.nroorden, conrec.centro, conrec.fechaemision, conrec.tipo, conrec.nroafiliado, conrec.importe, conrec.idformapagotipos, conrec.tformapago,
       conrec.idrecibo, conrec.idconcepto
       ,concat(to_char(comprobantestipos.idcomprobantetipos,'99') , ' - ' , comprobantestipos.ctdescripcion) as tcomprobante
       ,ccct.cuentacorrienteconceptotipodescrip
       ,CASE WHEN nullvalue(conrec.oetdescripcion) THEN 'Emitida'
       ELSE conrec.oetdescripcion END as oetdescripcion
       
       ,conrec.nrocuentac
       ,conrec.reci
FROM


(


/*se buscan los pagos de aportes*/
SELECT aporte.idaporte AS nroorden, aporte.idcentroregionaluso AS centro, recibo.fecharecibo AS fechaemision, 5 AS tipo,concat(  (concat(datoslaborales.nrodoc::text , '-'::text)) , btrim(to_char(datoslaborales.barra::double precision, '999'::text), ' '::text)) AS nroafiliado, aporte.impaporte AS importe, importesrecibo.idformapagotipos,concat( (to_char(formapagotipos.idformapagotipos, '99'::text) , ' - '::text) , formapagotipos.fpabreviatura::text) AS tformapago, recibo.idrecibo, 200 AS idconcepto,cuentascontables.nrocuentac
 ,CASE WHEN datoslaborales.barra>= 100 THEN 'TRUE'
          ELSE 'FALSE' END as reci, '' AS oetdescripcion
FROM recibo NATURAL JOIN importesrecibo NATURAL JOIN formapagotipos
JOIN ( SELECT aporte.idaporte, aporte.mes, aporte.ano, aporte.idcentroregionaluso, aporte.idlaboral, aporte.idrecibo,aporte.idcargo, aporte.idcertpers, aporte.fechaingreso, aporte.importe AS impaporte, aporte.nrocuentac
   FROM aporte) aporte ON (recibo.centro = aporte.idcentroregionaluso AND recibo.idrecibo = aporte.idrecibo)
  JOIN
   (SELECT persona.nrodoc, persona.barra, persona.tipodoc, datosper.idlaboral
    FROM
    (SELECT nrodoc, tipodoc, idcertpers AS idlaboral
     FROM afiljub
     UNION
     SELECT nrodoc, tipodoc, idcert AS idlaboral
     FROM afilpen
     UNION
     SELECT nrodoc, tipodoc, idcargo AS idlaboral
     FROM cargo) as datosper JOIN persona USING(nrodoc, tipodoc))
     datoslaborales USING(idlaboral) NATURAL JOIN cuentascontables
     WHERE (recibo.fecharecibo >=fechadesde AND recibo.fecharecibo < fechahasta)
      and (formapagotipos.fptseaplica ilike  'Tesoreria')
      and (idcentro=0 or recibo.centro = idcentro )

/*se buscan los pagos de clientes*/
    UNION
      SELECT  CASE when nullvalue(ccp.idcomprobante) then ccpna.idcomprobante  ELSE ccp.idcomprobante END AS nroorden, r.centro, r.fecharecibo AS fechaemision,
        mccct.idcomprobantetipos AS tipo
,concat(  (concat(CASE when nullvalue(ccp.nrodoc) then ccpna.nrodoc else ccp.nrodoc  END::text , '-'::text)) ,
 btrim(to_char(CASE when nullvalue(ccp.tipodoc) then ccpna.tipodoc else ccp.tipodoc END::double precision, '999'::text))) AS nroafiliado,  importesrecibo.importe, importesrecibo.idformapagotipos, concat( (concat(to_char(formapagotipos.idformapagotipos, '99'::text)) , ' - '::text) ,formapagotipos.fpabreviatura::text) AS tformapago, r.idrecibo,
CASE when nullvalue(ccp.idconcepto) then ccpna.idconcepto ELSE ccp.idconcepto END , CASE when nullvalue(ccp.nrocuentac) then ccpna.nrocuentac  ELSE ccp.nrocuentac  END
,CASE WHEN CASE when nullvalue(ccp.tipodoc) then ccpna.tipodoc  else ccp.tipodoc END>= 100 THEN 'TRUE' ELSE 'FALSE' END as reci
, '' AS oetdescripcion


 FROM recibo as r NATURAL JOIN importesrecibo NATURAL JOIN formapagotipos
 LEFT JOIN cuentacorrientepagos as ccp ON (r.idrecibo = ccp.idcomprobante AND r.centro=ccp.idcentropago AND ccp.idcomprobantetipos = 0)	
 LEFT JOIN ctactepagonoafil as ccpna ON (r.idrecibo = ccpna.idcomprobante AND r.centro=ccpna.idcentropago AND ccpna.idcomprobantetipos = 0)	
 JOIN mapeocuentascontablescomprobantestipos  AS mccct ON 
(CASE when nullvalue(ccp.nrocuentac) then ccpna.nrocuentac else ccp.nrocuentac END = mccct.nrocuentac)
WHERE ( not nullvalue(ccp.idpago) OR not nullvalue(ccpna.idpago) ) AND (r.fecharecibo >=fechadesde AND r.fecharecibo < fechahasta )
      and (idcentro=0 or r.centro = idcentro )
      and  formapagotipos.fptseaplica ilike  'Tesoreria'
) AS conrec  JOIN centroregional ON (centroregional.idcentroregional = conrec.centro)
JOIN direccion ON(centroregional.iddireccion=direccion.iddireccion )
JOIN comprobantestipos ON (comprobantestipos.idcomprobantetipos = conrec.tipo)
JOIN cuentacorrienteconceptotipo as ccct ON(ccct.idconcepto=conrec.idconcepto);



return true;
END;
$function$
