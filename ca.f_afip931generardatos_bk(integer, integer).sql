CREATE OR REPLACE FUNCTION ca.f_afip931generardatos_bk(integer, integer)
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
BEGIN
       elmesliq = $1;
       elanioliq = $2;
       sep_decimal = '.'; 
       sep_decimal_deseado = ',';
--
       SELECT INTO rliqsosunc * FROM ca.liquidacion WHERE  limes = elmesliq and  lianio = elanioliq  and (idliquidaciontipo=1 );

      SELECT INTO rliqfarma * FROM ca.liquidacion WHERE  limes = elmesliq and  lianio = elanioliq  and ( idliquidaciontipo=2);

       -- 1 - Elimino los registros generados para el mes de pago
      DELETE  FROM ca.afip_931 WHERE  limesliq = elmesliq and  lianioliq = elanioliq;

       -- 2 - Inserto los datos
      INSERT INTO ca.afip_931(limesliq,lianioliq,
idpersona,cuil,apeynom,argoafip,canthijos,codsituacion,codcondicion,codactividad,codzona,porcaportess,
codmodcontratacion,codos,cantadherente,remtotal,imponibleuno,asignacionesfam,impvoluntario,impadicional,impexcedentess,impexcedenteos,
provlocalidad,remimpdos,remimptre,remimpcuatro,codsiniestro,correspondereduccion,lrt,tipoempresa,aporteadicionalos,regimen,sitrevistauno,
diasitrevistauno,sitrevistados,diasitrevistados,sitrevista3,diasitrevistatres,sueldoyadic,sac,horasextras,impzonadesf,vacaciones,cantfiastrab,
remcinco,trabconvencionado,remseis,tipooperacion,montoadicionales,premio,remimpocho,remsiete,canthorasextras,noremunerativo,maternidad,
rectremu,remimnueve,conttareadiferencial,horastrabajadas,segvidaoblig,ley_27430,incrsalarial,remimponce)
(

        SELECT    limes as limesliq , lianio as lianioliq 
              ,idpersona, replace( replace(penrocuil,' ',''),'-','') as cuil,
              rpad( substr(UPPER(concatenar(concatenar(peapellido,' '),penombre)), 1, 30),30,'@') as apeynom,
           ---- VAS 071223   CASE WHEN (emacargoafip) THEN 'T'  ELSE 'F' END as argoafip,
   CASE WHEN (emacargoafip) THEN '1'  ELSE '0' END as argoafip,

              lpad( MAX(ca.conceptovalorempleado(idliquidacion, idpersona, 27,'p')),2,'0') as canthijos ,
         
 ---- VAS 071223      lpad(idafip_situacionrevista, 2,'0') as codsituacion,
    lpad(idafip_situacionrevista, 2,'0') as codsituacion,

 ---- VAS 071223               '01' as codcondicion,
'001' as codcondicion,

              CASE WHEN (MIN(idliquidaciontipo) =2 or MIN(idliquidaciontipo)=4 ) THEN '049'
                   WHEN (MIN(idliquidaciontipo) =1 or MIN(idliquidaciontipo)=3 ) THEN '017'
                   END as Codactividad,

  ---- VAS 071223                56 as codzona,
            '056' as codzona,

             lpad('0,00'::varchar ,5,'@')as porcaportess,

             CASE WHEN nullvalue(afip_idmodalidadcontrato) THEN '008'
                   ELSE    lpad(afip_idmodalidadcontrato, 3,'0')
                   END  as codmodcontratacion,

              lpad(emosafip_codobrasocial,6,'@') as codos,

              '00' as cantadherente,
--descomente q tenga en cuenta el 1135
              lpad( trunc((SUM(leimpbruto /*+ leimpasignacionfam*/ 
                             + ca.conceptovalorsac(limes,lianio,idpersona) 
--Dani comento 16032023 por pedido de Juan Manuel ya que para los legajos de farmacia se sumaba 2 veces el concepto 1135           
/*+ ca.conceptovalor(limes,lianio, idpersona, 1244,1135,1237 )*/
           
--5-08-2019 vas     + ca.conceptovalorempleado(idliquidacion, idpersona, 1135,'mf') 

) ) ::numeric,2)
            ---- VAS 071223          ,12,'@')
                                     ,15,'@')---- VAS 071223
                
as remtotal ,

            ---- VAS 071223    lpad(round(SUM(ca.f_remuneracionimponible (1, idpersona,idliquidacion,cemontofinal, (leimpbruto + leimpasignacionfam) ))::numeric,2) ,12,'@') as imponibleuno  ,
 lpad(round(SUM(ca.f_remuneracionimponible (1, idpersona,idliquidacion,cemontofinal, (leimpbruto + leimpasignacionfam) ))::numeric,2) ,15,'@') as imponibleuno  ,

        ---- VAS 071223        lpad('0.00' ,9,'@')as asignacionesfam ,
     lpad('0.00' ,15,'@')as asignacionesfam ,  ---- VAS 071223  

          ---- VAS 071223       lpad('0,00',9,'@') as impvoluntario ,
 lpad('0,00',15,'@') as impvoluntario ,

             ---- VAS 071223      lpad( '0,00' ,9,'@')as impadicional,
lpad( '0,00' ,15,'@')as impadicional,

         ---- VAS 071223         lpad( round(abs((ca.conceptovalorempleado(idliquidacion, idpersona, 1246,'mf')))::numeric,2 ) ,9,'@') as impexcedentess,
lpad( round(abs((ca.conceptovalorempleado(idliquidacion, idpersona, 1246,'mf')))::numeric,2 ) ,15,'@') as impexcedentess,

          ---- VAS 071223       lpad('0,00' ,9,'@') as  impexcedenteos,
lpad('0,00' ,15,'@') as  impexcedenteos,  ---- VAS 071223  

              rpad('Neuquen' ,50,'@')  as provlocalidad ,
              lpad(round(
                     (SUM(ca.f_remuneracionimponible (2, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )
                     +'0.01') ::numeric,2)
        ---- VAS 071223             ,12,'@')  as remimpdos ,
  ,15,'@')  as remimpdos , ---- VAS 071223     

        ---- VAS 071223        lpad(round( SUM( ca.f_remuneracionimponible (3, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )::numeric,2),12,'@')  as remimptre,
  lpad(round( SUM( ca.f_remuneracionimponible (3, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )::numeric,2),15,'@')  as remimptre,   ---- VAS 071223 

        ---- VAS 071223        lpad(round( SUM( ca.f_remuneracionimponible (4, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )::numeric,2) ,12,'@') as remimpcuatro ,
 
lpad(round( SUM( ca.f_remuneracionimponible (4, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )::numeric,2) ,15,'@') as remimpcuatro ,  ---- VAS 071223  

              '00' as codsiniestro,

        ---- VAS 071223       'F' as correspondereduccion,
  '0' as correspondereduccion,  ---- VAS 071223  

           ---- VAS 071223      lpad( '0,00' ,9,'@') as lrt,
 lpad( '0,00' ,15,'@') as lrt,      ---- VAS 071223   
           
   '0' as tipoempresa,
           

      ---- VAS 071223      lpad('0,00',9,'@') as aporteadicionalos,
     lpad('0,00',15,'@') as aporteadicionalos, ---- VAS 071223  

              '1' as regimen,

     --  VAS 071223        lpad(idafip_situacionrevista, 2,'0')as sitrevistauno,
  lpad(idafip_situacionrevista, 2,'0')as sitrevistauno,     --  VAS 071223   
              '01' as diasitrevistauno,
        
  --  VAS 071223       '01' as sitrevistados,
  '001' as sitrevistados, --  VAS 071223  
              '00' as diasitrevistados,
           
   --  VAS 071223    '01' as  sitrevista3,
 '001' as  sitrevista3, --  VAS 071223 
       
       '00' as diasitrevistatres ,

  --  VAS 071223   lpad(round(SUM(cemontofinal+ca.conceptovalorempleado(idliquidacion, idpersona, 1230,'mf') +ca.conceptovalorempleado(idliquidacion, idpersona, 1145,'mf')+ca.conceptovalorempleado(idliquidacion, idpersona, 1186,'mf'))::numeric,2) ,12,'@') as sueldoyadic ,
lpad(round(SUM(cemontofinal+ca.conceptovalorempleado(idliquidacion, idpersona, 1230,'mf') +ca.conceptovalorempleado(idliquidacion, idpersona, 1145,'mf')+ca.conceptovalorempleado(idliquidacion, idpersona, 1186,'mf'))::numeric,2) ,15,'@') as sueldoyadic ,  --  VAS 071223 

--Dani comento el 06-07-18 porq siempre traia cero             
-- lpad(SUM(ca.conceptovalorempleado(idliquidacion, idpersona, 32,'mf')),12,'@')  as sac ,
   
 --  VAS 071223            lpad(round(ca.conceptovalorsac(limes,lianio,idpersona)::numeric,2),12,'@') as sac,
           lpad(round(ca.conceptovalorsac(limes,lianio,idpersona)::numeric,2),15,'@') as sac,

           lpad( ( round(SUM( ca.conceptovalorempleado(idliquidacion, idpersona, 1152,'p')  +
                                 ca.conceptovalorempleado(idliquidacion, idpersona, 1133,'mf') +
                                 ca.conceptovalorempleado(idliquidacion, idpersona, 996,'mf')  +
                                 ca.conceptovalorempleado(idliquidacion, idpersona, 1176,'mf') +
                                 ca.conceptovalorempleado(idliquidacion, idpersona, 1151,'mf')
                            )::numeric,2)
                          
       --   VAS 071223      ),12,'0') as horasextras ,
  ),15,'0') as horasextras ,  --   VAS 071223 

              lpad( round( SUM( ca.conceptovalorempleado(idliquidacion, idpersona, 1051,'mf') +
                             ca.conceptovalorempleado(idliquidacion, idpersona, 14,'mf')   +
                             ca.conceptovalorempleado(idliquidacion, idpersona, 1173,'mf') +
                             ca.conceptovalorempleado(idliquidacion, idpersona, 1156,'mf') +
                --   VAS 071223                   ca.conceptovalorempleado(idliquidacion, idpersona, 1192,'mf'))::numeric,2 ) ,12,'@') as impzonadesf ,
  ca.conceptovalorempleado(idliquidacion, idpersona, 1192,'mf'))::numeric,2 ) ,15,'@') as impzonadesf ,   --   VAS 071223   
             
 lpad( (round ( SUM( ca.conceptovalorempleado(idliquidacion, idpersona, 1047,'mf') +
                             ca.conceptovalorempleado(idliquidacion, idpersona, 1068,'mf')  +
                             ca.conceptovalorempleado(idliquidacion, idpersona, 1046,'mf')
                     )::numeric,2)               
          --   VAS 071223           ) ,12,'@') as vacaciones ,
   ) ,15,'@') as vacaciones ,   --   VAS 071223

              CASE WHEN (MIN(idliquidaciontipo) = 1 or MIN(idliquidaciontipo) =3) THEN
                        lpad( MIN((ca.conceptovalorempleado(idliquidacion, idpersona, 1,'p')-ca.conceptovalorempleado(idliquidacion, idpersona, 1274,'p') -ca.conceptovalorempleado(idliquidacion, idpersona, 1145,'p'))), 9,'0')
                   WHEN (MIN(idliquidaciontipo) = 2 or MIN(idliquidaciontipo) =4) THEN
                        lpad( MIN((ca.conceptovalorempleado(idliquidacion, idpersona, 1028,'p')-ca.conceptovalorempleado(idliquidacion, idpersona, 1274,'p') -ca.conceptovalorempleado(idliquidacion, idpersona, 1145,'p'))), 9,'0')
              END  as cantfiastrab ,

   --   VAS 071223            lpad(round ( SUM(ca.f_remuneracionimponible (5, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )   ::numeric,2),12,'@')as remcinco ,

 lpad(round ( SUM(ca.f_remuneracionimponible (5, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )   ::numeric,2),15,'@')as remcinco ,  --   VAS 071223  

        --   VAS 071223       'F' as trabconvencionado, 
 '0' as trabconvencionado, --   VAS 071223 

     --   VAS 071223          lpad( '0,00',12,'@') as  remseis,
    lpad( '0,00',15,'@') as  remseis,   --   VAS 071223 

              '0' as tipooperacion,
       --   VAS 071223           lpad(round( SUM( ca.f_adicionalesmonto(idliquidacion, idpersona) )::numeric ,2) ,12,'@')  as montoadicionales ,
lpad(round( SUM( ca.f_adicionalesmonto(idliquidacion, idpersona) )::numeric ,2) ,15,'@')  as montoadicionales , --   VAS 071223 

        --   VAS 071223            lpad(round( SUM( ca.conceptovalorempleado(idliquidacion, idpersona, 4,'mf')+                                ca.conceptovalorempleado(idliquidacion, idpersona, 33,'mf'))::numeric,2) ,12,'@') as premio ,
lpad(round( SUM( ca.conceptovalorempleado(idliquidacion, idpersona, 4,'mf')+
                               ca.conceptovalorempleado(idliquidacion, idpersona, 33,'mf'))::numeric,2) ,15,'@') as premio ,--   VAS 071223 

   --   VAS 071223            lpad(round( SUM( ca.f_remuneracionimponible (8 ,idpersona,idliquidacion ,cemontofinal,(leimpbruto + leimpasignacionfam)))::numeric,2),12,'@')as remimpocho ,
 lpad(round( SUM( ca.f_remuneracionimponible (8 ,idpersona,idliquidacion ,cemontofinal,(leimpbruto + leimpasignacionfam)))::numeric,2),15,'@')as remimpocho ,  --   VAS 071223 

         --   VAS 071223        lpad('0,00',12,'@') as  remsiete ,
  lpad('0,00',15,'@') as  remsiete , --   VAS 071223 
              lpad(  ( round(SUM(   ca.conceptovalorempleado(idliquidacion, idpersona, 1152,'m') +
                              ca.conceptovalorempleado(idliquidacion, idpersona, 1133,'p') +
                              ca.conceptovalorempleado(idliquidacion, idpersona, 996,'p')  +
                              ca.conceptovalorempleado(idliquidacion, idpersona, 1176,'p') +
                              ca.conceptovalorempleado(idliquidacion, idpersona, 1151,'p'))
                             ::numeric,0)) ,3,'0')as canthorasextras,

/*dani 2021-07-07 lo dejo asi pero hay q mejorarlo*/
              CASE WHEN (MIN(idliquidaciontipo)=2 or MIN(idliquidaciontipo)=4) THEN    
                   
 -- VAS 071223    lpad(round(SUM(abs(leimpnoremunerativo)/*+(0.5*ca.conceptovalor(limes,lianio, idpersona, 1135))*/)::numeric,2),12,'@')  
    lpad(round(SUM(abs(leimpnoremunerativo)/*+(0.5*ca.conceptovalor(limes,lianio, idpersona, 1135))*/)::numeric,2),15,'@')  
              --   VAS 071223 
                   ELSE
--- VAS 071223 lpad(round(SUM(abs(leimpnoremunerativo)+ca.conceptovalor(limes,lianio, idpersona, 1244,1237,1135))::numeric,2)  ,12,'@')          
lpad(round(SUM(abs(leimpnoremunerativo)+ca.conceptovalor(limes,lianio, idpersona, 1244,1237,1135))::numeric,2)  ,15,'@')      --- VAS 071223     

             
              END as  noremunerativo,

         --- VAS 071223      lpad( round(SUM(  ca.conceptovalorempleado(idliquidacion, idpersona, 1105,'mf'))::numeric,2),12,'@') as maternidad,
lpad( round(SUM(  ca.conceptovalorempleado(idliquidacion, idpersona, 1105,'mf'))::numeric,2),15,'@') as maternidad,   --- VAS 071223 

      --- VAS 071223           lpad('0,00' ,9,'@')as rectremu,
 lpad('0,00' ,15,'@')as rectremu,  --- VAS 071223

    --- VAS 071223          lpad(round( SUM( ca.f_remuneracionimponible (9, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )::numeric,2) ,12,'@') as remimnueve,
 lpad(round( SUM( ca.f_remuneracionimponible (9, idpersona,idliquidacion,cemontofinal,(leimpbruto + leimpasignacionfam)) )::numeric,2) ,15,'@') as remimnueve,    --- VAS 071223 

      --- VAS 071223           lpad('0,00',9,'@') as conttareadiferencial,
  lpad('0,00',15,'@') as conttareadiferencial,  --- VAS 071223 

        --- VAS 071223           '000' as horastrabajadas,
 '000000000000000' as horastrabajadas,   --- VAS 071223 
           
   'T' as segvidaoblig,    --- VAS 071223    ????? no lo encontramos en la V41

               --lpad( '17509.20',12,'@')  as ley_27430,
      --- VAS 071223         lpad( '0.00',12,'@')  as ley_27430,  ??? no esta 
lpad( '0.00',15,'@')  as ley_27430,     --- VAS 071223    

          --- VAS 071223           lpad( '0.00',12,'@')  as incrsalarial,
        lpad( '0.00',15,'@')  as incrsalarial,            --- VAS 071223    
            --- VAS 071223         lpad( '0.00',12,'@')  as remimponce
  lpad( '0.00',15,'@')  as remimponce   --- VAS 071223    
     FROM(
      
SELECT limes, lianio ,idpersona,penrocuil,peapellido,penombre,emacargoafip,idliquidacion,idafip_situacionrevista,idliquidaciontipo,afip_idmodalidadcontrato,ca.obrasocial.emosafip_codobrasocial,leimpbruto,cemontofinal,leimpasignacionfam
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
      WHERE lianio = elanioliq and limes = elmesliq 
            and (idconcepto=1 or  idconcepto=1028 )  --or idconcepto=32 or idconcepto=1092
      UNION 
       SELECT elmesliq as limes, elanioliq as lianio,idpersona,penrocuil,peapellido,penombre,emacargoafip,

case when (ca.grupoliquidacionempleado.idgrupoliquidaciontipo=1)then rliqsosunc.idliquidacion else rliqfarma.idliquidacion end as idliquidacion,
idafip_situacionrevista,

case when (ca.grupoliquidacionempleado.idgrupoliquidaciontipo=1)then rliqsosunc.idliquidaciontipo else rliqfarma.idliquidaciontipo end as idliquidaciontipo,afip_idmodalidadcontrato,ca.obrasocial.emosafip_codobrasocial,0 as leimpbruto,0 as cemontofinal,0 as leimpasignacionfam,0 as leimpnoremunerativo

 

        FROM ca.empleado
        NATURAL JOIN ca.persona     
         LEFT JOIN (SELECT * 
                  FROM ca.liquidacionempleado
                  NATURAL JOIN  ca.liquidacion
                  WHERE  lianio = elanioliq and limes = elmesliq 
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

        WHERE  ( nullvalue (liq.idpersona) )
               AND ( asrafechadesde<=concat(elanioliq ,'-',elmesliq ,'-','01') ::date) 
               AND (nullvalue(asrefechahasta) OR asrefechahasta>=concat(elanioliq ,'-',elmesliq ,'-','01') ::date )
                      
                 AND (idafip_situacionrevista=13 OR idafip_situacionrevista=5 OR idafip_situacionrevista=10) ---- 13 Licencia sin goce de haberes 
                                                                                                             ----  5 Licencia por maternidad
                                                                                                             ---- 10 Licencia por excedencia   
                 
      ) AS T
  --where idpersona=82    
      GROUP BY limesliq,lianioliq,idpersona,cuil,apeynom,argoafip ,codsituacion,codcondicion,codzona,porcaportess,codmodcontratacion,codos,cantadherente,impexcedentess
   );
  
  SELECT INTO cant count(*) FROM ca.afip_931  WHERE  limesliq = elmesliq and lianioliq = elanioliq;
      
return cant;
END;$function$
