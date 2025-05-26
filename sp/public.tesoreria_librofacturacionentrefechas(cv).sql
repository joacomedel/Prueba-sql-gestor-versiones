CREATE OR REPLACE FUNCTION public.tesoreria_librofacturacionentrefechas(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
   pfechadesde VARCHAR;
   pfechahasta VARCHAR;
   pagrupados VARCHAR; --Si es 'Agrupados' muestra la informacion de resumenes y facturas sin resumen
   pcatgastos VARCHAR; --Si es cero, quiere decir que son todas las categorias menos la 4. 
   pidprestador VARCHAR; --Si es cero, quiere decir que no se filtra prestador. 
 
--RECORD
   rparam RECORD;

BEGIN

EXECUTE sys_dar_filtros($1) INTO rparam;  
pfechadesde =rparam.fechadesde;
pfechahasta =rparam.fechadesde;
pagrupados =rparam.fechadesde;  
pidprestador=rparam.fechadesde;
 
IF iftableexists('tablareporteentrefechas') THEN
	DROP TABLE tablareporteentrefechas;
END IF;
IF iftableexists('tablareporteentrefechas_titulos') THEN
	DROP TABLE tablareporteentrefechas_titulos;
END IF;



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
 
       ,'1-Recepcion#apellido@2-Nro.Registro#nombres@3-Prestador#nrodoc@4-Observaciones#nroafiliado@5-Factura#fechanac@6-Importe#edad@7-Debito#fechainios@8-A Pagar#grupofamiliar@9-F.Emision Fact.#titular@10-F.Vto.Fact.#descrip@11-Minuta de Pago#titular@12-Fecha MP#descrip@13-Fecha.Operacion#titular@14-OP. Multivac#descrip@15-Nro. Operacion#descrip@16-Cta. Sosunc#titular@17-Imp.Operacion#descrip@18-Notas de Debito#descrip@19-Fecha Emision ND#titular@20-Forma Pago#descrip@21-Fecha Cont#descrip@22-Id. Prestador#titular@23-MMAA#descrip@24-Auditado#descrip@25-Pagado#titular@26-Tipo Prestador#descrip@27-CUIT#descrip'::text as mapeocampocolumna
  
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
--KR 19-05-22 agrego el parametro 5
            AND (idprestador = pidprestador OR pidprestador = 0)
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
--KR 19-05-22 agrego el parametro 5
            AND (idprestador = pidprestador OR pidprestador = 0)
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
                LEFT JOIN (SELECT split_part(idcomprobantesiges,'|',1)::bigint as nroordenpago ,split_part(idcomprobantesiges,'|',2)::integer as    idcentroordenpago,MIN(agfechacontable)as agfechacontable, MIN(agefechafin) agefechafin
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
       --KR 19-05-22 agrego el parametro 5
            AND (idprestador = pidprestador OR pidprestador = 0)
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
                 --KR 19-05-22 agrego el parametro 5
            AND (idprestador = pidprestador OR pidprestador = 0)
--KR 07-01-21 Pidio Andrea P que no se muestren los debitos desemputados 
                  AND case when NOT nullvalue(mpsiges.debito) then mpsiges.debito <>0 else 0=0 end 
                 ORDER BY rlf.numeroregistro
           
           
           
           
     );

end if;
	
RETURN 'true';
END;$function$
