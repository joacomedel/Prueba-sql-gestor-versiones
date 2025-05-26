CREATE OR REPLACE FUNCTION ca.f_afip931generardatos(integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
rliq record ;
       cant integer;
       elmesliq integer;
       elanioliq integer;
       rinfo record;
       rliqsosunc record;
       rliqfarma record;
       sep_decimal varchar;
       sep_decimal_deseado varchar;
       tope_actual double precision;	
BEGIN
       elmesliq = $1;
       elanioliq = $2;
       sep_decimal = '.'; 
       sep_decimal_deseado = ',';

       SELECT INTO tope_actual ctmontomaximo	 FROM ca.conceptotope WHERE nullvalue(ctfechahasta) AND idconcepto = 200;


--
       SELECT INTO rliqsosunc * FROM ca.liquidacion WHERE  limes = elmesliq and  lianio = elanioliq  and (idliquidaciontipo=1 );

      SELECT INTO rliqfarma * FROM ca.liquidacion WHERE  limes = elmesliq and  lianio = elanioliq  and ( idliquidaciontipo=2);

       -- 1 - Elimino los registros generados para el mes de pago
      DELETE  FROM ca.afip_931 WHERE  limesliq = elmesliq and  lianioliq = elanioliq;
----  DATE_PART('year', lifecha) = elanioliq                AND  DATE_PART('month', lifecha) = elmesliq 
       -- 2 - Inserto los datos
      INSERT INTO ca.afip_931(limesliq,lianioliq,
idpersona,cuil,apeynom,argoafip,canthijos,codsituacion,codcondicion,codactividad,codzona,porcaportess,
codmodcontratacion,codos,cantadherente,remtotal,imponibleuno,asignacionesfam,impvoluntario,impadicional,impexcedentess,impexcedenteos,
provlocalidad,remimpdos,remimptre,remimpcuatro,codsiniestro,correspondereduccion,lrt,tipoempresa,aporteadicionalos,regimen,sitrevistauno,
diasitrevistauno,sitrevistados,diasitrevistados,sitrevista3,diasitrevistatres,sueldoyadic,sac,horasextras,impzonadesf,vacaciones,cantfiastrab,
remcinco,trabconvencionado,remseis,tipooperacion,montoadicionales,premio,remimpocho,remsiete,canthorasextras,noremunerativo,maternidad,
rectremu,remimnueve,conttareadiferencial,horastrabajadas,segvidaoblig,ley_27430,incrsalarial,remimponce)
(

        SELECT  limes  as limesliq , lianio as lianioliq 
              ,idpersona, replace( replace(penrocuil,' ',''),'-','') as cuil,
              rpad( substr(UPPER(concatenar(concatenar(peapellido,' '),penombre)), 1, 30),30,'@') as apeynom,
              CASE WHEN (emacargoafip) THEN 'T'  ELSE 'F' END as argoafip,
              lpad( MAX(ca.conceptovalorempleado(idliquidacion, idpersona, 27,'p')),2,'0') as canthijos ,
              lpad(idafip_situacionrevista, 2,'0') as codsituacion,
              '01' as codcondicion,
              CASE WHEN (MIN(idliquidaciontipo) =2 or MIN(idliquidaciontipo)=4 ) THEN '049'
                   WHEN (MIN(idliquidaciontipo) =1 or MIN(idliquidaciontipo)=3 ) THEN '017'
                   END as Codactividad,
              56 as codzona,
             lpad('0,00'::varchar ,5,'@')as porcaportess,
             CASE WHEN nullvalue(afip_idmodalidadcontrato) THEN '008'
                   ELSE    lpad(afip_idmodalidadcontrato, 3,'0')
                   END  as codmodcontratacion,
              case when not nullvalue(emosafip_codobrasocial) THEN lpad(emosafip_codobrasocial,6,'@') else '000000' end as codos,
              '00' as cantadherente,
--descomente q tenga en cuenta el 1135
               lpad( trunc((SUM(leimpbruto) + ca.conceptovalorsac(limes,lianio,idpersona) ) ::numeric,2)
                    ,12,'@')
                as remtotal ,


---- buscar tope
         /*  case when sum(ca.f_remuneracionimponible (1, idpersona,idliquidacion,cemontofinal, (leimpbruto + leimpasignacionfam) )) >=tope_actual  THEN   
           lpad(round(tope_actual::numeric,2) ,12,'@')
ELSE 
*/


 

 lpad(round((sum(ca.f_remuneracionimponible (1, idpersona,idliquidacion,cemontofinal, (leimpbruto + leimpasignacionfam) )))::numeric,2) ,12,'@') 
as imponibleuno,
--END

 
         

              lpad('0.00' ,9,'@')as asignacionesfam ,
              lpad('0,00',9,'@') as impvoluntario ,
              lpad( '0,00' ,9,'@')as impadicional,
              lpad( round(abs((ca.conceptovalorempleado(idliquidacion, idpersona, 1246,'mf')))::numeric,2 ) ,9,'@') as impexcedentess,
              lpad('0,00' ,9,'@') as  impexcedenteos,
              rpad('Neuquen' ,50,'@')  as provlocalidad ,
              lpad(round(
                     (SUM(ca.f_remuneracionimponible (2, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )
                     +'0.01') ::numeric,2)
               ,12,'@')  as remimpdos ,
              lpad(round( SUM( ca.f_remuneracionimponible (3, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )::numeric,2),12,'@')  as remimptre,
              lpad(round( SUM( ca.f_remuneracionimponible (4, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )::numeric,2) ,12,'@') as remimpcuatro ,
              '00' as codsiniestro,
              'F' as correspondereduccion,
              lpad( '0,00' ,9,'@') as lrt,
              '0' as tipoempresa,
              lpad('0,00',9,'@') as aporteadicionalos,
              '1' as regimen,
              lpad(idafip_situacionrevista, 2,'0')as sitrevistauno,
              '01' as diasitrevistauno,
              '01' as sitrevistados,
              '00' as diasitrevistados,
              '01' as  sitrevista3,
              '00' as diasitrevistatres ,
 lpad(round(SUM(cemontofinal+ 
				ca.conceptovalorempleado(idliquidacion, idpersona, 1230,'mf') 
				+ca.conceptovalorempleado(idliquidacion, idpersona, 1145,'mf')
				+ca.conceptovalorempleado(idliquidacion, idpersona, 1186,'mf'))::numeric,2) ,12,'@') as sueldoyadic ,

--Dani comento el 06-07-18 porq siempre traia cero             
-- lpad(SUM(ca.conceptovalorempleado(idliquidacion, idpersona, 32,'mf')),12,'@')  as sac ,
              lpad(round(ca.conceptovalorsac(limes,lianio,idpersona)::numeric,2),12,'@') as sac,

              lpad( ( round(SUM( ca.conceptovalorempleado(idliquidacion, idpersona, 1152,'p')  +
                                 ca.conceptovalorempleado(idliquidacion, idpersona, 1133,'mf') +
                                 ca.conceptovalorempleado(idliquidacion, idpersona, 996,'mf')  +
                                 ca.conceptovalorempleado(idliquidacion, idpersona, 1176,'mf') +
                                 ca.conceptovalorempleado(idliquidacion, idpersona, 1151,'mf')
                            )::numeric,2)
                          
              ),12,'0') as horasextras ,

              lpad( round( SUM( ca.conceptovalorempleado(idliquidacion, idpersona, 1051,'mf') +
                             ca.conceptovalorempleado(idliquidacion, idpersona, 14,'mf')   +
                             ca.conceptovalorempleado(idliquidacion, idpersona, 1173,'mf') +
                             ca.conceptovalorempleado(idliquidacion, idpersona, 1156,'mf') +
                             ca.conceptovalorempleado(idliquidacion, idpersona, 1192,'mf'))::numeric,2 ) ,12,'@') as impzonadesf ,
              lpad( (round ( SUM( ca.conceptovalorempleado(idliquidacion, idpersona, 1047,'mf') +
                             ca.conceptovalorempleado(idliquidacion, idpersona, 1068,'mf')  +
                             ca.conceptovalorempleado(idliquidacion, idpersona, 1046,'mf')
                     )::numeric,2)               
                 ) ,12,'@') as vacaciones ,

                 CASE WHEN (MIN(idliquidaciontipo) = 1 or MIN(idliquidaciontipo) =3) THEN
                        lpad( MIN((ca.conceptovalorempleado(idliquidacion, idpersona, 1,'p')-ca.conceptovalorempleado(idliquidacion, idpersona, 1274,'p') -ca.conceptovalorempleado(idliquidacion, idpersona, 1145,'p'))), 9,'0')
                   WHEN (MIN(idliquidaciontipo) = 2 or MIN(idliquidaciontipo) =4) THEN
                        lpad( MIN((ca.conceptovalorempleado(idliquidacion, idpersona, 1028,'p')-ca.conceptovalorempleado(idliquidacion, idpersona, 1274,'p') -ca.conceptovalorempleado(idliquidacion, idpersona, 1145,'p'))), 9,'0')
              END  as cantfiastrab ,

              lpad(round ( SUM(ca.f_remuneracionimponible (5, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )   ::numeric,2),12,'@')as remcinco ,
              'F' as trabconvencionado,
              lpad( '0,00',12,'@') as  remseis,
              '0' as tipooperacion,
              lpad(round( SUM( ca.f_adicionalesmonto(idliquidacion, idpersona) )::numeric ,2) ,12,'@')  as montoadicionales ,
              lpad(round( SUM( ca.conceptovalorempleado(idliquidacion, idpersona, 4,'mf')+
                               ca.conceptovalorempleado(idliquidacion, idpersona, 33,'mf'))::numeric,2) ,12,'@') as premio ,
              lpad(round( SUM( ca.f_remuneracionimponible (8 ,idpersona,idliquidacion ,cemontofinal,(leimpbruto + leimpasignacionfam)))::numeric,2),12,'@')as remimpocho ,
              lpad('0,00',12,'@') as  remsiete ,
              lpad(  ( round(SUM(   ca.conceptovalorempleado(idliquidacion, idpersona, 1152,'m') +
                              ca.conceptovalorempleado(idliquidacion, idpersona, 1133,'p') +
                              ca.conceptovalorempleado(idliquidacion, idpersona, 996,'p')  +
                              ca.conceptovalorempleado(idliquidacion, idpersona, 1176,'p') +
                              ca.conceptovalorempleado(idliquidacion, idpersona, 1151,'p'))
                             ::numeric,0)) ,3,'0')as canthorasextras,
/*dani 2021-07-07 lo dejo asi pero hay q mejorarlo*/
              CASE WHEN (MIN(idliquidaciontipo)=2 or MIN(idliquidaciontipo)=4) THEN    
                   
  lpad(round(SUM(abs(leimpnoremunerativo)/*+(0.5*ca.conceptovalor(limes,lianio, idpersona, 1135))*/)::numeric,2),12,'@')  
             
                   ELSE
lpad(round(SUM(abs(leimpnoremunerativo)
			    ---- NOOOOO se cambia por los posteriores llamados +ca.conceptovalor(limes,lianio, idpersona, 1244,1237,1135)
			  
			    +ca.conceptovalorempleado(idliquidacion, idpersona, 1244 ,'mf')
			     +ca.conceptovalorempleado(idliquidacion, idpersona, 1237,'mf')
			     +ca.conceptovalorempleado(idliquidacion, idpersona, 1135,'mf')
			  )::numeric,2)  ,12,'@')                       
              END as  noremunerativo,
              lpad( round(SUM(  ca.conceptovalorempleado(idliquidacion, idpersona, 1105,'mf'))::numeric,2),12,'@') as maternidad,
              lpad('0,00' ,9,'@')as rectremu,
              lpad(round( SUM( ca.f_remuneracionimponible (9, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )::numeric,2) ,12,'@') as remimnueve,
              lpad('0,00',9,'@') as conttareadiferencial,
              '000' as horastrabajadas,
              'T' as segvidaoblig,
               --lpad( '17509.20',12,'@')  as ley_27430,
             lpad( '0.00',12,'@')  as ley_27430,
             lpad( '0.00',12,'@')  as incrsalarial,
               
             lpad( '0.00',12,'@')  as remimponce
     FROM(
      
SELECT  DATE_PART('month', lifecha)::integer limes, DATE_PART('year', lifecha)::integer lianio ,idpersona,penrocuil,peapellido,penombre,emacargoafip,idliquidacion,idafip_situacionrevista,idliquidaciontipo,afip_idmodalidadcontrato,ca.obrasocial.emosafip_codobrasocial,leimpbruto,cemontofinal,leimpasignacionfam
,leimpnoremunerativo
      FROM ca.empleado
      NATURAL JOIN ca.persona
      NATURAL JOIN ca.contratotipo

      NATURAL JOIN ca.liquidacionempleado
      NATURAL JOIN ca.liquidacion
      NATURAL JOIN ca.conceptoempleado
      NATURAL JOIN ca.empleadoobrasocial
      JOIN ca.obrasocial on(ca.empleadoobrasocial.idobrasocial=ca.obrasocial.idobrasocial)  
      LEFT JOIN   (SELECT idpersona,max(asrafechadesde) as asrafechadesde  
                   FROM ca.afip_situacionrevistaempleado
       /*Dani descomenta el idafip_situacionrevista<>13*/            
       WHERE -- idafip_situacionrevista<>13 and  
                       (nullvalue(asrefechahasta) or asrefechahasta>=concat(elanioliq ,'-',elmesliq ,'-','01') ::date ) 
                   GROUP BY idpersona

       ) as f USING (idpersona)
      LEFT JOIN ca.afip_situacionrevistaempleado using (idpersona,asrafechadesde)
      LEFT JOIN ca.afip_situacionrevista using (idafip_situacionrevista)
      LEFT JOIN (
        SELECT idempleado as idpersona, emacargoafip
        FROM ca.empleadopersona
        WHERE idvinculo = 1  -- conyuge
      ) as cony using (idpersona )
      WHERE   --- comento VAS 04/04 para que tome en cuenta la fecha de la liquidacion NO el mes y año al que corresponden 
              --- comento VAS 04/04  lianio = elanioliq and limes = elmesliq  
               DATE_PART('year', lifecha) = elanioliq 
               AND  DATE_PART('month', lifecha) = elmesliq 
             
            and (idconcepto=1 or  idconcepto=1028 )  --or idconcepto=32 or idconcepto=1092
UNION 
  SELECT elmesliq as limes, elanioliq as lianio,idpersona,penrocuil,peapellido,penombre,emacargoafip,
    case when (ca.grupoliquidacionempleado.idgrupoliquidaciontipo=1)then rliqsosunc.idliquidacion else rliqfarma.idliquidacion end as idliquidacion,
    idafip_situacionrevista,
    case when (ca.grupoliquidacionempleado.idgrupoliquidaciontipo=1)then rliqsosunc.idliquidaciontipo 
    else rliqfarma.idliquidaciontipo end as   idliquidaciontipo,afip_idmodalidadcontrato,
    ca.obrasocial.emosafip_codobrasocial,0 as leimpbruto,0 as cemontofinal,0 as leimpasignacionfam,0 as leimpnoremunerativo

       FROM ca.empleado
        NATURAL JOIN ca.persona     
        LEFT JOIN (SELECT * 
                  FROM ca.liquidacionempleado
                  NATURAL JOIN  ca.liquidacion
                  WHERE  ---- lianio = elanioliq and limes = elmesliq 
                         DATE_PART('year', lifecha) = elanioliq 
                         AND  DATE_PART('month', lifecha) = elmesliq 
        ) as liq USING(idpersona)   
        NATURAL JOIN ca.empleadoobrasocial
        NATURAL JOIN ca.contratotipo
        natural join ca.grupoliquidacionempleado
        JOIN ca.obrasocial on(ca.empleadoobrasocial.idobrasocial=ca.obrasocial.idobrasocial)
        NATURAL JOIN ca.afip_situacionrevistaempleado
        LEFT JOIN (
                SELECT idempleado as idpersona, emacargoafip
                FROM ca.empleadopersona
                WHERE idvinculo = 1  -- conyuge
         ) as cony using (idpersona )

        WHERE  TRUE -- AND ( nullvalue (liq.idpersona) )  /* 29-12-2023 Modif por Caso Balercia*/
                AND ( asrafechadesde<=concat(elanioliq ,'-',elmesliq ,'-','01') ::date) 
            
              

               --AND (nullvalue(asrefechahasta) OR asrefechahasta>=concat(elanioliq ,'-',elmesliq ,'-','01') ::date )
               --Dani agrega para que no traiga en ambas partes de la consulta aquellos casos q tiene una parte del mes como activos y otra parte como LSGH
                AND (nullvalue(asrefechahasta) OR asrefechahasta>=concat(elanioliq ,'-',elmesliq ,'-','01') ::date +  interval '1 month' - interval  '1 day')
                     
                AND (idafip_situacionrevista=13 OR idafip_situacionrevista=5 OR idafip_situacionrevista=10) ---- 13 Licencia sin goce de haberes 
                                                                                                             ----  5 Licencia por maternidad
                                                                                                             ---- 10 Licencia por excedencia   
                 
      ) AS T
    --where idpersona=82    
      GROUP BY limesliq,lianioliq,idpersona,cuil,
        apeynom,argoafip ,codsituacion,codcondicion,codzona,porcaportess,codmodcontratacion,codos,cantadherente,impexcedentess
   );
  
SELECT INTO cant count(*) FROM ca.afip_931  WHERE  limesliq = elmesliq and lianioliq = elanioliq;
      
return cant;
END;$function$
