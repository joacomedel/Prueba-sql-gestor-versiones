CREATE OR REPLACE FUNCTION public.conciliacionbancaria_conciliarmovimientosbanco(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
    rusuario RECORD;
    cbancamov_ppal  CURSOR FOR  SELECT * FROM  temp_bancamovimiento order by idbancamovimiento asc; -- temporal con los movimientos de la banca que se desean conciliar
    cbancamov CURSOR FOR SELECT * FROM  temp_bancamovimiento order by idbancamovimiento asc; -- temporal con los comprobantes de SIGES que se desean conciliar
    rbancamov record;
    rcmovsiges record;
    resp boolean;
    cant integer;
    rfiltros RECORD;
    disponible double precision;
disponible_ppal double precision;

    monto_conciliar  double precision;
    monto_real_conc double precision;
    imp_sin_conc_siges  double precision;
    elidconitem bigint;
 elidbancamovimiento bigint;
    parametros character varying;

  
    rcbancamov_ppal record;
BEGIN
     EXECUTE sys_dar_filtros($1) INTO rfiltros;
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN
        rusuario.idusuario = 25;
     END IF;
     cant = 0;
 

 --  Aqui los cursores quedan apuntando al mismo record
     OPEN cbancamov_ppal ;
     FETCH cbancamov_ppal  INTO rcbancamov_ppal ;  
     WHILE found LOOP
            cant = 0 ;
            
           
         
          OPEN cbancamov;
          FETCH cbancamov INTO rbancamov;  
          WHILE found LOOP
                 

                   -- SI se tratan de movimientos del banco diferentes 
                   -- AND un movimiento tiene afecta al D (debe) y el otro al H (haber)
                   -- ENTOCES puedo intentar conciliarlos
                     cant =2 + cant;
                    IF (rcbancamov_ppal.idbancamovimiento <> rbancamov.idbancamovimiento ) 
                        AND (   (rcbancamov_ppal.bmcredito>0 AND rbancamov.bmdebito>0 )OR(rcbancamov_ppal.bmdebito>0 AND rbancamov.bmcredito>0)) THEN
                      
                          cant =2 + cant;
                          RAISE NOTICE '>>>>>>>>>>>>>>>>ID movBanco a conciliar rcbancamov_ppal=  (%) , rbancamov= (%) 
 >>>>>>>>>>>>>>>>',rcbancamov_ppal.idbancamovimiento,rbancamov.idbancamovimiento;
                 
                          -- 1 calculo el importe disponible del movimiento del banco ppal
                          SELECT  INTO disponible_ppal  ((abs(bmdebito) + abs(bmcredito)) - conciliacionbancaria_montoconciliado(idbancamovimiento::varchar,'{tipomov=banco}') )
                          FROM bancamovimiento
                          WHERE idbancamovimiento = rcbancamov_ppal.idbancamovimiento;
                          RAISE NOTICE 'imp. disponible (%) en rcbancamov_ppal.idbancamovimiento = (%)',disponible_ppal,rcbancamov_ppal.idbancamovimiento;
 
                          -- 2 calculo el importe disponible del otro movimiento del banco
                          SELECT  INTO disponible  ((abs(bmdebito) + abs(bmcredito)) - conciliacionbancaria_montoconciliado(idbancamovimiento::varchar,'{tipomov=banco}') )
                          FROM bancamovimiento
                          WHERE idbancamovimiento = rbancamov.idbancamovimiento;
                 
		            RAISE NOTICE 'imp. disponible (%) en rbancamov.idbancamovimiento = (%)',disponible_ppal,rbancamov.idbancamovimiento;

                              
                          monto_conciliar = disponible - disponible_ppal ;
                
                           RAISE NOTICE 'monto_conciliar  (%)',monto_conciliar ;                          

                
                          -- Analizo si los disponibles de los movimientos seleccionados alcanzan para conciliar 
                          IF(disponible>0 AND disponible_ppal >0 ) THEN

                                  -- Analizo el monto a conciliar 
                                  IF(monto_conciliar<=0 ) THEN-- el monto de disponible_ppal es > pago
                                         monto_real_conc = disponible;
                                         RAISE NOTICE 'monto_real_conc = disponible (%)',monto_real_conc;
                                      
                                   ELSE
                                          monto_real_conc = disponible_ppal;
                                          RAISE NOTICE 'monto_real_conc = disponible_ppal(%)',monto_real_conc;
                                       
                                   END IF;

                                   --- 2 - Creo el item de la conciliacion
                                   IF(monto_real_conc>0) THEN 
                                             RAISE NOTICE 'Se crean 2 item de conciliación  uno por cada movimiento del banco a conciliar (%) con (%) ', rcbancamov_ppal.idbancamovimiento,  rbancamov.idbancamovimiento;
                                        --- Se crean 2 item de conciliación, uno por cada movimiento del banco a conciliar 
                                      INSERT INTO conciliacionbancariaitem(cbitablacomp,cbiclavecompsiges ,idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idusuario,cbiautomatica,cbiimporte,cbicomsiges,cbicomsigesdetalle)
                                 VALUES('bancamovimiento' ,concat('idbancamovimiento=',rbancamov.idbancamovimiento)   , rfiltros.idconciliacionbancaria,rfiltros.idcentroconciliacionbancaria,rcbancamov_ppal.idbancamovimiento,rusuario.idusuario,FALSE,monto_real_conc,
concat('bancamovimiento/bancamovimiento',rbancamov.idbancamovimiento,'/',rcbancamov_ppal.idbancamovimiento), concat('Conciliacion entre mov. del banco ',rbancamov.idbancamovimiento,'/',rcbancamov_ppal.idbancamovimiento) );

                                        INSERT INTO conciliacionbancariaitem(cbitablacomp,cbiclavecompsiges ,idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idusuario,cbiautomatica,cbiimporte,cbicomsiges,cbicomsigesdetalle)
                                 VALUES('bancamovimiento' ,concat('idbancamovimiento=',rcbancamov_ppal.idbancamovimiento), rfiltros.idconciliacionbancaria,rfiltros.idcentroconciliacionbancaria,rbancamov.idbancamovimiento,rusuario.idusuario,FALSE,monto_real_conc,
concat('bancamovimiento/bancamovimiento',rbancamov.idbancamovimiento, '/' ,rcbancamov_ppal.idbancamovimiento), concat('Conciliacion entre mov. del banco ',rbancamov.idbancamovimiento,'/',rcbancamov_ppal.idbancamovimiento));
                                          -- elidconitem = currval('conciliacionbancariaitem_idconciliacionbancariaitem_seq');
                           ELSE 
                                   RAISE NOTICE 'El monto real a conciliar es = (%)',  monto_real_conc;
                                      
                           END IF; -- IF(monto_real_conc>0) 

                         cant = cant + 2;
                   ELSE 
                                   RAISE NOTICE 'No se verifica la condicion   -- disponible>0 (%) y disponible_ppal  >0  (%)',  disponible , disponible_ppal  ;
                 END IF;--IF(disponible>0 AND disponible_ppal >0 )
               ELSE 
                     RAISE NOTICE 'No se verifica la condicion  (rcbancamov_ppal.bmcredito= (%)  >0 AND rbancamov.bmdebito (%) =0 ) o (rcbancamov_ppal.bmcredito (%) > 0 AND rbancamov.bmdebito (%) >0)', rcbancamov_ppal.bmcredito, rbancamov.bmdebito,rcbancamov_ppal.bmcredito,rbancamov.bmdebito;
               END IF;-- IF  ..... (rcbancamov_ppal.bmcredito>0 AND rbancamov.bmdebito=0 )or(rcbancamov_ppal.bmcredito=0 AND rbancamov.bmdebito>0) 
  

          FETCH cbancamov INTO rbancamov;
          END LOOP;
          CLOSE cbancamov;
          
          FETCH cbancamov_ppal INTO rcbancamov_ppal;
     END LOOP;
     CLOSE cbancamov_ppal;

return cant;
END;$function$
