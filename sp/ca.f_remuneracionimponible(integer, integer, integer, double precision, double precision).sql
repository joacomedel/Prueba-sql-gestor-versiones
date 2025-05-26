CREATE OR REPLACE FUNCTION ca.f_remuneracionimponible(integer, integer, integer, double precision, double precision)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE

        monto  DOUBLE PRECISION;
        emontofinal  DOUBLE PRECISION;
        remtotal DOUBLE PRECISION;
    
       montosac  DOUBLE PRECISION;
       elmontotope  record;
       lapersona integer;
       laliq integer;
       imponible integer;
       rliqcierre record;
       rliqsac record;
       tienelsgh record;
      
BEGIN
       imponible = $1;
       lapersona = $2;
       laliq = $3;
       emontofinal = $4;
       remtotal = $5;
monto = 0;
       select into elmontotope * 
       FROM ca.conceptotope
       WHERE  idconcepto = 200
              and nullvalue(ctfechahasta);

       SELECT INTO rliqcierre SUM(leimpbruto)::DOUBLE PRECISION as leimpbruto, SUM(leimpasignacionfam)::DOUBLE PRECISION as leimpasignacionfam, SUM(leimpnoremunerativo)::DOUBLE PRECISION as leimpnoremunerativo,limes,lianio
       FROM ca.liquidacionempleado
       NATURAL JOIN ca.liquidacion 
       WHERE  idpersona = lapersona
              AND idliquidacion = laliq
       GROUP BY limes,lianio;

       IF NOT  FOUND THEN -- si NO hay una liq para el empleado 

                    SELECT INTO rliqcierre 0::DOUBLE PRECISION as leimpbruto , 0::DOUBLE PRECISION as leimpasignacionfam, 0::DOUBLE PRECISION as leimpnoremunerativo,limes,lianio
                    FROM ca.liquidacion
                    WHERE  idliquidacion = laliq;
       END IF;
        /*Busco la info del SAC 3=sac sosunc 4= sac farmacia*/
             SELECT INTO rliqsac CASE WHEN (nullvalue(SUM(leimpbruto)) ) THEN 0 ELSE SUM(leimpbruto) END as leimpbruto , SUM(leimpasignacionfam)as leimpasignacionfam,       SUM(leimpnoremunerativo)as leimpnoremunerativo,limes,lianio 
             FROM ca.liquidacionempleado
             NATURAL JOIN ca.liquidacion 
             WHERE  idpersona = lapersona
                    AND limes = rliqcierre.limes and lianio = rliqcierre.lianio and ( idliquidaciontipo = 3 or  idliquidaciontipo = 4 ) 
             GROUP BY limes,lianio;
       IF NOT FOUND THEN
                    SELECT INTO rliqsac   0 as leimpbruto , 0 as leimpasignacionfam,       0 as leimpnoremunerativo, rliqcierre.limes, rliqcierre.lianio  
                    FROM ca.liquidacion;
       END IF ;

             montosac =  ca.conceptovalorsac(rliqcierre.limes,rliqcierre.lianio,lapersona) ;
             remtotal = remtotal + montosac ;
             IF ( imponible=1 OR imponible = 3 OR imponible = 4 OR imponible = 5  OR imponible = 8 ) THEN
                -- SAC ya q la aplicacion de afip usada por Julieta  informa que 
                --la remuneracion imponible 2 debe coincidir con el sueldo + adicionales + hs extra + plus x zona + sac + vac


                        RAISE NOTICE 'monto montosac, r.leimpbruto ,r.leimpasignacionfam ,r.leimpnoremunerativo(%)(%)(%)(%) ',montosac , rliqcierre.leimpbruto ,rliqcierre.leimpasignacionfam ,rliqcierre.leimpnoremunerativo;
                        monto =  montosac +rliqcierre.leimpbruto + rliqcierre.leimpasignacionfam-rliqcierre.leimpnoremunerativo;
RAISE NOTICE 'monto monto(%) ',monto;
             
             END IF ;
    
              IF ( imponible= 2 ) THEN
                   monto = trunc(emontofinal::numeric,2)    -- sueldo
                        + montosac
                        + ca.f_adicionalesmonto(laliq, lapersona)                 -- adicionales
                        + ca.conceptovalorempleado(laliq, lapersona, 4,'mf')      -- premio
                        + ca.conceptovalorempleado(laliq, lapersona, 33,'mf')     -- sup premio
                       
                        + (   ca.conceptovalorempleado(laliq, lapersona, 1152,'p')+
                              ca.conceptovalorempleado(laliq, lapersona, 1133,'mf')+
                              ca.conceptovalorempleado(laliq, lapersona, 996,'mf')+
                              ca.conceptovalorempleado(laliq, lapersona, 1176,'mf')+
                              ca.conceptovalorempleado(laliq, lapersona, 1151,'mf')
                            ) -- horas extras
                      +  ( ca.conceptovalorempleado(laliq, lapersona, 1051,'mf')+
                           ca.conceptovalorempleado(laliq, lapersona, 14,'mf')+
                           ca.conceptovalorempleado(laliq, lapersona, 1173,'mf')+
                           ca.conceptovalorempleado(laliq, lapersona, 1156,'mf')+
                           ca.conceptovalorempleado(laliq, lapersona, 1192,'mf')
                           )

                      +   ( ca.conceptovalorempleado(laliq, lapersona, 1047,'mf')+
                            ca.conceptovalorempleado(laliq, lapersona, 1068,'mf')+
                            ca.conceptovalorempleado(laliq, lapersona, 1046,'mf')

                     
                            )
--Por pedido de JE, segun mail 31102024 se debe restar el concepto 1274. Como este tiene valor negativo se hace la suma.
                      +    ca.conceptovalorempleado(laliq, lapersona, 1274,'mf');  --vacaciones
              END IF;
  
  
              IF ( imponible = 9 ) THEN
                    monto = rliqcierre.leimpbruto ;
                    IF (montosac <> 0) THEN
                        monto = monto + rliqsac.leimpbruto;
                    END IF; 
              END IF;

              IF  (imponible <> 2 and (monto - remtotal )>0 and (monto - remtotal )<1  ) THEN
                    monto = remtotal;
              RAISE NOTICE ' if imponible <> 2 and (monto - remtotal )>0 and (monto - remtotal )<1 THEN(%) ',monto;
             END IF;
       
        
              
              IF  ( (imponible = 1 OR imponible = 4  OR imponible= 5 )AND monto >=elmontotope.ctmontomaximo) THEN
                        if (montosac = 0) THEN
                            monto =elmontotope.ctmontomaximo;
                        RAISE NOTICE ' if montosac = 0   THEN(%) ',monto;
                         END IF;
                     if (montosac > 0 and monto >=(elmontotope.ctmontomaximo*1.5) ) THEN
                            monto = (elmontotope.ctmontomaximo)*1.5;
                            RAISE NOTICE ' if montosac > 0 and monto >=elmontotope.ctmontomaximo*1.5   THEN(%) ',monto;
                    
                     END IF;
               END IF;
     ---  END IF;
return round(monto::numeric,2);
--return trunc((monto-'0.01')::numeric,2);

END;
$function$
