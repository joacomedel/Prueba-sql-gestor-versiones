CREATE OR REPLACE FUNCTION public.tesoreria_librofacturacionentrefechas(date, date, character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	pfechadesde alias for $1;
	pfechahasta alias for $2;
	pagrupados alias for $3; --Si es 'Agrupados' muestra la informacion de resumenes y facturas sin resumen
	pcatgastos alias for $4; --Si es cero, quiere decir que son todas las categorias menos la 4. 
	
BEGIN
IF iftableexists('tablareporteentrefechas') THEN
	DROP TABLE tablareporteentrefechas;
END IF;
IF iftableexists('tablareporteentrefechas_titulos') THEN
	DROP TABLE tablareporteentrefechas_titulos;
END IF;

CREATE TEMP TABLE tablareporteentrefechas_titulos(nrooperacion varchar,nroordenpagomultivac varchar
,minutapago varchar,numfactura varchar,notasdebito varchar,nroregistroformato varchar,importedelpago varchar
,apagar varchar,debito varchar,monto varchar,tipoformapagodesc varchar
,cuentasosunc varchar,obs varchar,pdescripcion varchar,fechaoperacion varchar,fechavenc varchar,fechaemision varchar
,fecharecepcion varchar ,fechaingreso VARCHAR,fenotadebito VARCHAR
, agfechacontable varchar, idprestador varchar
/*KR 17-02-20 Se modifica a pedido de LAURA*/
, mesanio VARCHAR, auditado VARCHAR, pagado VARCHAR, tipoprestador VARCHAR,pcuit VARCHAR/*,idasientocontable VARCHAR*/
);
INSERT INTO tablareporteentrefechas_titulos(nrooperacion,nroordenpagomultivac,minutapago,numfactura,notasdebito,nroregistroformato,importedelpago,apagar,debito,monto,tipoformapagodesc
,cuentasosunc,obs,pdescripcion,fechaingreso,fechaoperacion,fechavenc,fechaemision,fecharecepcion,agfechacontable,fenotadebito, idprestador
, mesanio, auditado, pagado, tipoprestador,pcuit /*,idasientocontable*/
) 
VALUES('15-Nro. Operacion','14-OP. Multivac','11-Minuta de Pago','5-Factura',
'17-Notas de Debito','2-Nro.Registro','17-Imp.Operacion','8-A Pagar','7-Debito','6-Importe','19-Forma Pago'
,'16-Cta. Sosunc','4-Observaciones','3-Prestador','12-Fecha MP','13-Fecha.Operacion','10-F.Vto.Fact.','9-F.Emision Fact.','1-Recepcion','20-Fecha Cont', '18-Fecha Emision ND', '21-Id. Prestador'
, '22-MMAA', '23-Auditado', '24-Pagado', '25-Tipo Prestador','26-CUIT'/*,'27-ID Asiento Contable'*/);

if nullvalue(pcatgastos) OR pcatgastos<>0 then

CREATE TEMP TABLE tablareporteentrefechas as (
SELECT 
       recepcion.idrecepcion,rlf.numeroregistro, rlf.anio
       ,rlf.idprestador,prestador.pcuit,prestador.pdescripcion,rlf.obs
       ,rlf.numfactura, CASE WHEN rlf.idtipocomprobante = 4 THEN rlf.monto*-1 ELSE rlf.monto END as monto, to_char(recepcion.fecha,'DD/MM/YYYY') as fecharecepcion
       , concat(rlf.numeroregistro, '-',  rlf.anio) as nroregistroformato
       ,case when nullvalue(mpsiges.debito) then 0 else mpsiges.debito end as debito,
       (CASE WHEN rlf.idtipocomprobante = 4 THEN rlf.monto*-1 ELSE rlf.monto END -case when nullvalue(mpsiges.debito) then 0 else mpsiges.debito end) as apagar
       ,mpsiges.nroordenpago as minutapago,mpsiges.fechaingreso as fechaingreso
       /*Agrego Dani 2015-09-07*/
       /*,mpsiges.idcentroordenpago as idcentroordenpago*/
       ,to_char(rlf.fechaemision,'DD/MM/YYYY')  as fechaemision ,to_char(rlf.fechavenc,'DD/MM/YYYY') as fechavenc
       ,to_char(datospago.fechaoperacion,'DD/MM/YYYY') as fechaoperacion
       ,datospago.nroordenpago as nroordenpagomultivac
       ,datospago.nrooperacion ::varchar -- vas 11-11-17
       ,datospago.cuentasosunc
       ,datospago.importe as importedelpago
       ,datospago.tipoformapagodesc
       ,mpsiges.nrofacturaconformato as notasdebito
       ,mpsiges.agfechacontable as agfechacontable
       ,fenotadebito--, idprestador::bigint
       ,to_char(recepcion.fecha, 'MMYYYY') as mesanio
       ,CASE WHEN nullvalue(mpsiges.nroordenpago) THEN 'No Auditado' ELSE 'Auditado' END  as auditado
       ,CASE WHEN nullvalue(tipoformapagodesc) THEN 'No Pagado' ELSE 'Pagado' END as pagado 
       ,CASE WHEN nullvalue(mpo.idprestador) THEN 'Prestaciones' ELSE 'Reciprocidad' END as tipoprestador
      /* ,CASE WHEN nullvalue(ag.idasientogenerico) THEN ' ' ELSE concat(ag.idasientogenerico,'|',ag.idcentroasientogenerico) END AS idasientocontable*/
FROM recepcion 
NATURAL JOIN reclibrofact as rlf JOIN festados AS fe ON rlf.numeroregistro= fe.nroregistro AND rlf.anio=fe.anio
NATURAL JOIN prestador  LEFT JOIN mapeoprestadorosreci mpo USING(idprestador)  /*osreci 	*/
/*LEFT JOIN asientogenerico ag ON ( idcomprobantesiges = concat(rlf.numeroregistro,'|',rlf.anio))	
LEFT JOIN asientogenericoestado USING(idasientogenerico,idcentroasientogenerico)		*/
LEFT JOIN (SELECT CASE WHEN nullvalue(idresumen) THEN  f.nroregistro ELSE idresumen END as nroregistro
              , CASE WHEN nullvalue(anioresumen) THEN  f.anio ELSE anioresumen END as anio
              , f.nroordenpago
              ,f.idcentroordenpago
              , ordenpago.fechaingreso
               ,sum(debito) as debito
              , text_concatenar((nrofacturaconformato)) as nrofacturaconformato
              , agfechacontable ,fenotadebito
            FROM factura as f 
/*Agrego Dani 2015-09-07*/
            JOIN ordenpago ON(f.nroordenpago=ordenpago.nroordenpago and f.idcentroordenpago=ordenpago.idcentroordenpago)	
            LEFT JOIN (SELECT split_part(idcomprobantesiges,'|',1)::bigint as nroordenpago ,split_part(idcomprobantesiges,'|',2)::integer as    idcentroordenpago,MIN(agfechacontable) as agfechacontable
                       FROM asientogenerico
                       NATURAL JOIN asientogenericoestado
                       WHERE idasientogenericocomprobtipo = 4 and nullvalue(agefechafin) -- and tipoestadofactura = 7 --Sincronizado
   --KR 21-03-19  tipoestadofactura = 1 AND agfechacontable>='2019-01-01' son confiables. Los previos no (hablado con CS)
                 and tipoestadofactura = 1 AND agfechacontable>='2019-01-01'
                       group by idcomprobantesiges
            )as agmp ON (agmp.nroordenpago = ordenpago.nroordenpago AND agmp.idcentroordenpago =  ordenpago.idcentroordenpago ) 

	    LEFT JOIN (SELECT  nroregistro,anio,concat(tipofactura , ' ' , to_char(nrosucursal, '0000') , '-' ,  to_char(nrofactura, '00000000')) AS nrofacturaconformato
				               ,sum(importectacte)  as debito, fechaemision as fenotadebito
		       FROM (
		            SELECT nroregistro,anio,nroinforme,idcentroinformefacturacion
		            FROM  debitofacturaprestador
			    NATURAL JOIN informefacturacionnotadebito
			    GROUP BY nroregistro,anio,nroinforme,idcentroinformefacturacion
			) as debitos
			JOIN informefacturacion USING(nroinforme,idcentroinformefacturacion)
			JOIN facturaventa USING(nrofactura, tipocomprobante, nrosucursal, tipofactura)	
			WHERE nullvalue(anulada) 
			      --and nroregistro = 86156  	
			GROUP BY fenotadebito,nroregistro,anio,concat(tipofactura , ' ' , to_char(nrosucursal, '0000') , '-' ,  to_char(nrofactura, '00000000'))
			ORDER BY nroregistro,anio,concat(tipofactura , ' ' , to_char(nrosucursal, '0000') , '-' ,  to_char(nrofactura, '00000000'))

			) as facprestaciones ON(f.nroregistro=facprestaciones.nroregistro AND f.anio=facprestaciones.anio) 
            WHERE f.ffecharecepcion >= pfechadesde AND f.ffecharecepcion <= pfechahasta	 
            GROUP BY CASE WHEN nullvalue(anioresumen) THEN  f.anio ELSE anioresumen END,
		     CASE WHEN nullvalue(idresumen) THEN  f.nroregistro ELSE idresumen END,
               /*Agrego Dani 2015-09-07*/
                      f.nroordenpago,f.idcentroordenpago,ordenpago.fechaingreso,agfechacontable,fenotadebito
              ) as mpsiges ON(rlf.numeroregistro=mpsiges.nroregistro AND rlf.anio=mpsiges.anio) 			
/*pagados */ 
LEFT JOIN  (

--CS 2018-11-27 agrego agrupación porque aparecian tuplas espurias ya que existen en ordenpagocontablereclibrofact mas de 1 ordenpagocontable para 1 reclibrofact
select nroregistro,	anio,	max(fechaoperacion) fechaoperacion,	text_concatenar(concat(nroordenpago,' - ')) as nroordenpago,	max(idcentroordenpago) idcentroordenpago,	max(nrooperacion) nrooperacion,	max(cuentasosunc) cuentasosunc,	max(tipoformapagodesc) tipoformapagodesc,	max(importe) importe,	max(observaciones) observaciones,	max(nroopsiges) nroopsiges
 from (

SELECT CASE WHEN nullvalue(idresumen) THEN  opmdp.nroregistro::integer ELSE idresumen END as nroregistro
		           ,CASE WHEN nullvalue(anioresumen) THEN  opmdp.anio::integer ELSE anioresumen END as  anio
		           , fechaoperacion,opmdp.nroordenpago, opmdp.idcentroordenpago
                   ,nrooperacion::varchar  --vas 11-11-17
                   ,cuentasosunc,tipoformapagodesc,importe,observaciones,nroopsiges
            FROM  factura as f
		    JOIN ordenpagomultivacdatospago AS opmdp ON(f.nroregistro::integer=opmdp.nroregistro and f.anio=opmdp.anio)
		    NATURAL JOIN tipoformapago
		    GROUP BY CASE WHEN nullvalue(anioresumen) THEN  opmdp.anio::integer ELSE anioresumen END,
		             CASE WHEN nullvalue(idresumen) THEN  opmdp.nroregistro::integer ELSE idresumen END,
		             fechaoperacion,opmdp.nroordenpago,opmdp.idcentroordenpago,nrooperacion,cuentasosunc,tipoformapagodesc,importe,observaciones,nroopsiges

      /* AGRAGA VAS 24/08/2017 para que tome los pagos de las nuevas OPC*/
           UNION
           SELECT numeroregistro as nroregistro
                  , anio
--                , bofechapago as fechaoperacion 
                  , case when not nullvalue(bofechapago) then bofechapago else ordenpagocontable.opcfechaingreso end as fechaoperacion  --CS 2018-07-02
                  , idordenpagocontable as nroordenpago
                  , idcentroordenpagocontable as idcentroordenpago
                  , bonrooperacion::varchar as nrooperacion -- vas 11-11-17
                  , descripcion as cuentasosunc 
--CS 2018-11-18 Aunque hayan pagado con cheque siempre aparecía TRANSFERENCIA, porque toma el tipo del valor de la cuenta bancaria, por ej. 45 que corresponde a CredicoopNqn
--                , fpdescripcion as tipoformapagodesc
                  , case when nullvalue(idcheque) then fpdescripcion else 'CHEQUE' end as tipoformapagodesc 
---------------
                  , popmonto as importe
                  , popobservacion as observaciones , (idordenpagocontable*100)+idcentroordenpagocontable as nroopsiges
           FROM ordenpagocontablereclibrofact
           JOIN ordenpagocontable using (idcentroordenpagocontable, idordenpagocontable)
           JOIN ordenpagocontableestado using (idcentroordenpagocontable, idordenpagocontable)
           LEFT JOIN pagoordenpagocontable using(idordenpagocontable,idcentroordenpagocontable)
           LEFT JOIN valorescaja using(idvalorescaja)
           LEFT JOIN formapagotipos using(idformapagotipos)
           LEFT JOIN ordenpagocontablebancatransferencia using (idcentropagoordenpagocontable ,idpagoordenpagocontable)
           LEFT JOIN bancatransferencia using (idbancatransferencia)
           LEFT JOIN bancaoperacion using (idbancaoperacion)
          
           WHERE  nullvalue(opcfechafin) AND  idordenpagocontableestadotipo<>6   --No tenga en cuenta las anuladas
                 and idvalorescaja <>67 -- Para que no se vean las retenciones suss
                 and idvalorescaja <>65 -- Para que no se vean las retenciones ganancias
           /* AGRAGA VAS 24/08/2017   END*/

--KR 14-01-19 agrego los pagos a cuenta de facturas 
     
      UNION 
         SELECT numeroregistro as nroregistro
                  , anio 
                  , case when not nullvalue(bofechapago) then bofechapago else opc.opcfechaingreso end as fechaoperacion  
                  , idordenpagocontable as nroordenpago
                  , idcentroordenpagocontable as idcentroordenpago
                  , bonrooperacion::varchar as nrooperacion -- vas 11-11-17
                  , descripcion as cuentasosunc 
                  , case when nullvalue(idcheque) then fpdescripcion else 'CHEQUE' end as tipoformapagodesc 
                  , popmonto as importe
                  , popobservacion as observaciones , (idordenpagocontable*100)+idcentroordenpagocontable as nroopsiges

           FROM ordenpagocontable opc NATURAL JOIN ordenpagocontableestado
           JOIN ctactepagoprestador ccp ON (ccp.idcomprobante=opc.idordenpagocontable*10+opc.idcentroordenpagocontable AND  
           ccp.idcomprobantetipos=40) NATURAL JOIN prestadorctacte JOIN prestador USING(idprestador)  
           JOIN ctactedeudapagoprestador USING(idpago, idcentropago) JOIN ctactedeudaprestador using(iddeuda, idcentrodeuda)
           JOIN reclibrofact rlf ON (numeroregistro*10000+anio= ctactedeudaprestador.idcomprobante)

 
            
           LEFT JOIN pagoordenpagocontable using(idordenpagocontable,idcentroordenpagocontable)
           LEFT JOIN valorescaja using(idvalorescaja)
           LEFT JOIN formapagotipos using(idformapagotipos)
           LEFT JOIN ordenpagocontablebancatransferencia using (idcentropagoordenpagocontable ,idpagoordenpagocontable)
           LEFT JOIN bancatransferencia using (idbancatransferencia)
           LEFT JOIN bancaoperacion using (idbancaoperacion)
          
           WHERE  nullvalue(opcfechafin) AND  idordenpagocontableestadotipo<>6   --No tenga en cuenta las anuladas
                 and idvalorescaja <>67 -- Para que no se vean las retenciones suss
                 and idvalorescaja <>65 -- Para que no se vean las retenciones ganancias

              

) as x
group by nroregistro,	anio

            ) AS datospago 	ON(rlf.numeroregistro=datospago.nroregistro and rlf.anio=datospago.anio) 			

WHERE recepcion.fecha >= pfechadesde AND recepcion.fecha <= pfechahasta /* AND nullvalue(agefechafin)*/
--MaLaPi 07-04-2017 si la categoria de gastos es nula, quiero todas
         AND (nullvalue(pcatgastos) OR (not nullvalue(pcatgastos) AND rlf.catgasto=pcatgastos ))
         AND nullvalue(idrecepcionresumen)  and fe.tipoestadofactura<>5 AND nullvalue(fe.fefechafin)
--AND idprestador = 2375
--AND numeroregistro
--KR 07-01-21 Pidio Andrea P que no se muestren los debitos desemputados 
AND case when NOT nullvalue(mpsiges.debito) then mpsiges.debito <>0  else 0=0 end 

      ORDER BY rlf.numeroregistro
);

else

CREATE TEMP TABLE tablareporteentrefechas as (
SELECT 
       recepcion.idrecepcion,rlf.numeroregistro, rlf.anio
       ,rlf.idprestador,prestador.pdescripcion,rlf.obs
       ,rlf.numfactura, CASE WHEN rlf.idtipocomprobante = 4 THEN rlf.monto*-1 ELSE rlf.monto END as monto, to_char(recepcion.fecha,'DD/MM/YYYY') as fecharecepcion
       , concat(rlf.numeroregistro, '-',  rlf.anio) as nroregistroformato
       ,case when nullvalue(mpsiges.debito) then 0 else mpsiges.debito end as debito,
       (CASE WHEN rlf.idtipocomprobante = 4 THEN rlf.monto*-1 ELSE rlf.monto END -case when nullvalue(mpsiges.debito) then 0 else mpsiges.debito end) as apagar
       ,mpsiges.nroordenpago as minutapago
       /*Agrego Dani 2015-09-07*/
       /*,mpsiges.idcentroordenpago as idcentroordenpago*/
       ,to_char(rlf.fechaemision,'DD/MM/YYYY')  as fechaemision ,to_char(rlf.fechavenc,'DD/MM/YYYY') as fechavenc
       ,to_char(datospago.fechaoperacion,'DD/MM/YYYY') as fechaoperacion
       ,datospago.nroordenpago as nroordenpagomultivac
       ,datospago.nrooperacion::varchar -- vas 11-11-17
       ,datospago.cuentasosunc
       ,datospago.importe as importedelpago
       ,datospago.tipoformapagodesc
       ,mpsiges.nrofacturaconformato as notasdebito
       ,mpsiges.agfechacontable as agfechacontable
       ,to_char(recepcion.fecha, 'MMYYYY')
       ,CASE WHEN nullvalue(mpsiges.nroordenpago) THEN 'No Auditado' ELSE 'Auditado' END  as auditado
       ,CASE WHEN nullvalue(tipoformapagodesc) THEN 'No Pagado' ELSE 'Pagado' END as pagado 
       ,CASE WHEN nullvalue(mpo.idprestador) THEN 'Prestaciones' ELSE 'Reciprocidad' END as tipoprestador
--KR 26-01-21 A pedido de Andrea
    /*   ,CASE WHEN nullvalue(ag.idasientogenerico) THEN ' ' ELSE concat(ag.idasientogenerico,'|',ag.idcentroasientogenerico) END AS idasientocontable
*/
       FROM recepcion
       NATURAL JOIN reclibrofact as rlf JOIN festados AS fe ON rlf.numeroregistro= fe.nroregistro AND rlf.anio=fe.anio
       NATURAL JOIN prestador LEFT JOIN mapeoprestadorosreci mpo USING(idprestador)  /*osreci 	*/		
    /*   LEFT JOIN asientogenerico ag ON ( idcomprobantesiges = concat(rlf.numeroregistro,'|',rlf.anio))	
       LEFT JOIN asientogenericoestado using(idasientogenerico,idcentroasientogenerico)
    */                  	
       LEFT JOIN (SELECT CASE WHEN nullvalue(idresumen) THEN  f.nroregistro ELSE idresumen END as nroregistro
                         , CASE WHEN nullvalue(anioresumen) THEN  f.anio ELSE anioresumen END as anio
                         , f.nroordenpago
                         , f.idcentroordenpago
                         , ordenpago.fechaingreso
                         , sum(debito) as debito
                         , text_concatenar((nrofacturaconformato)) as nrofacturaconformato
                         , agfechacontable
                FROM factura as f
/*Agrego Dani 2015-09-07*/
                JOIN ordenpago ON(f.nroordenpago=ordenpago.nroordenpago and f.idcentroordenpago=ordenpago.idcentroordenpago)	
                LEFT JOIN (SELECT split_part(idcomprobantesiges,'|',1)::bigint as nroordenpago ,split_part(idcomprobantesiges,'|',2)::integer as    idcentroordenpago,MIN(agfechacontable)as agfechacontable
                       FROM asientogenerico
                       NATURAL JOIN asientogenericoestado
                       WHERE idasientogenericocomprobtipo = 4  -- and tipoestadofactura = 7 --Sincronizado
   --KR 21-03-19  tipoestadofactura = 1 AND agfechacontable>='2019-01-01' son confiables. Los previos no (hablado con CS)
                 and tipoestadofactura = 1 AND agfechacontable>='2019-01-01'
                       group by idcomprobantesiges
            )as agmp ON (agmp.nroordenpago = ordenpago.nroordenpago AND agmp.idcentroordenpago =  ordenpago.idcentroordenpago ) 
	            LEFT JOIN (SELECT  nroregistro,anio,concat(tipofactura , ' ' , to_char(nrosucursal, '0000') , '-' ,  to_char(nrofactura, '00000000')) AS nrofacturaconformato
				                   ,sum(importectacte)  as debito
			              FROM (
				               SELECT nroregistro,anio,nroinforme,idcentroinformefacturacion
                     			FROM  debitofacturaprestador
				                NATURAL JOIN informefacturacionnotadebito
				                GROUP BY nroregistro,anio,nroinforme,idcentroinformefacturacion
			               ) as debitos
			              JOIN informefacturacion USING(nroinforme,idcentroinformefacturacion)
			              JOIN facturaventa USING(nrofactura, tipocomprobante, nrosucursal, tipofactura)	
			              WHERE nullvalue(anulada)
			                    --and nroregistro = 86156  	
                          GROUP BY nroregistro,anio,concat(tipofactura , ' ' , to_char(nrosucursal, '0000') , '-' ,  to_char(nrofactura, '00000000'))
			              ORDER BY nroregistro,anio,concat(tipofactura , ' ' , to_char(nrosucursal, '0000') , '-' ,  to_char(nrofactura, '00000000'))

			) as facprestaciones ON(f.nroregistro=facprestaciones.nroregistro AND f.anio=facprestaciones.anio) 
            WHERE f.ffecharecepcion >= pfechadesde AND f.ffecharecepcion <= pfechahasta	and nullvalue(agefechafin)
	        GROUP BY   CASE WHEN nullvalue(anioresumen) THEN  f.anio ELSE anioresumen END,
		    CASE WHEN nullvalue(idresumen) THEN  f.nroregistro ELSE idresumen END,
/*Agrego Dani 2015-09-07*/
                    f.nroordenpago,f.idcentroordenpago,ordenpago.fechaingreso,agfechacontable
              ) as mpsiges ON(rlf.numeroregistro=mpsiges.nroregistro AND rlf.anio=mpsiges.anio) 			
/*pagados */ 
LEFT JOIN  (

--CS 2018-11-27 agrego agrupación porque aparecian tuplas espurias ya que existen en ordenpagocontablereclibrofact mas de 1 ordenpagocontable para 1 reclibrofact
select nroregistro,	anio,	max(fechaoperacion) fechaoperacion,	text_concatenar(concat(nroordenpago,' - ')) as nroordenpago,	max(idcentroordenpago) idcentroordenpago,	max(nrooperacion) nrooperacion,	max(cuentasosunc) cuentasosunc,	max(tipoformapagodesc) tipoformapagodesc,	max(importe) importe,	max(observaciones) observaciones,	max(nroopsiges) nroopsiges
 from (

SELECT  CASE WHEN nullvalue(idresumen) THEN  opmdp.nroregistro::integer ELSE idresumen END as nroregistro
		           ,CASE WHEN nullvalue(anioresumen) THEN  opmdp.anio::integer ELSE anioresumen END as  anio
		           ,fechaoperacion,opmdp.nroordenpago, opmdp.idcentroordenpago
                   ,nrooperacion::varchar -- vas 11-11-17
                   ,cuentasosunc,tipoformapagodesc,importe,observaciones,nroopsiges
		    FROM factura as f
		    JOIN ordenpagomultivacdatospago AS opmdp ON(f.nroregistro::integer=opmdp.nroregistro and f.anio=opmdp.anio)
		    NATURAL JOIN tipoformapago
		    GROUP BY CASE WHEN nullvalue(anioresumen) THEN  opmdp.anio::integer ELSE anioresumen END,
                     CASE WHEN nullvalue(idresumen) THEN  opmdp.nroregistro::integer ELSE idresumen END,
		                  fechaoperacion,opmdp.nroordenpago,opmdp.idcentroordenpago,nrooperacion,cuentasosunc,tipoformapagodesc,importe,observaciones,nroopsiges

           /* AGRAGA VAS 24/08/2017 para que tome los pagos de las nuevas OPC*/
           UNION
           SELECT numeroregistro nroregistro, anio,bofechapago as fechaoperacion , idordenpagocontable as nroordenpago
                  ,idcentroordenpagocontable as idcentroordenpago
                  ,bonrooperacion::varchar as nrooperacion
                  ,descripcion as cuentasosunc 
--CS 2018-11-18 Aunque hayan pagado con cheque siempre aparecía TRANSFERENCIA, porque toma el tipo del valor de la cuenta bancaria, por ej. 45 que corresponde a CredicoopNqn
--                ,fpdescripcion as tipoformapagodesc
                  ,case when nullvalue(idcheque) then fpdescripcion else 'CHEQUE' end as tipoformapagodesc 
---------------
                  , popmonto as importe
                  , popobservacion as observaciones , (idordenpagocontable*100)+idcentroordenpagocontable as nroopsiges
           FROM ordenpagocontablereclibrofact
           JOIN ordenpagocontableestado using (idcentroordenpagocontable, idordenpagocontable)
           LEFT JOIN pagoordenpagocontable using(idordenpagocontable,idcentroordenpagocontable)
           LEFT JOIN valorescaja using(idvalorescaja)
           LEFT JOIN formapagotipos using(idformapagotipos)
           LEFT JOIN ordenpagocontablebancatransferencia using (idcentropagoordenpagocontable ,idpagoordenpagocontable)
           LEFT JOIN bancatransferencia using (idbancatransferencia)
           LEFT JOIN bancaoperacion using (idbancaoperacion)
           WHERE   nullvalue(opcfechafin) AND  idordenpagocontableestadotipo<>6   --No tenga en cuenta las anuladas
                 and idvalorescaja <>67 -- Para que no se vean las retenciones suss
                 and idvalorescaja <>65 -- Para que no se vean las retenciones ganancias
           /* AGRAGA VAS 24/08/2017   END*/

) as x
group by nroregistro,	anio

            ) AS datospago 	ON(rlf.numeroregistro=datospago.nroregistro and rlf.anio=datospago.anio) 			
            WHERE recepcion.fecha >= pfechadesde AND recepcion.fecha <= pfechahasta
                  AND rlf.catgasto<>4
                  AND nullvalue(idrecepcionresumen)
                  and fe.tipoestadofactura<>5
                  AND nullvalue(fe.fefechafin)
                  --AND idprestador = 2375
                  --AND numeroregistro
--KR 07-01-21 Pidio Andrea P que no se muestren los debitos desemputados 
                  AND case when NOT nullvalue(mpsiges.debito) then mpsiges.debito <>0 else 0=0 end 
                 ORDER BY rlf.numeroregistro
           
           
           
           
     );

end if;
	
RETURN 'true';
END;$function$
