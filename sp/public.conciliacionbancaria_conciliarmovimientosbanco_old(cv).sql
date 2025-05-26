CREATE OR REPLACE FUNCTION public.conciliacionbancaria_conciliarmovimientosbanco_old(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
    rusuario RECORD;
    cbancamov CURSOR FOR SELECT * FROM  temp_bancamovimiento; -- temporal con los movimientos de la banca que se desean conciliar
    cbancamov_ppal CURSOR FOR SELECT * FROM  temp_bancamovimiento; -- temporal con los comprobantes de SIGES que se desean conciliar
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
    parametros character varying;

  
    rcbancamov_ppal record;
BEGIN
     EXECUTE sys_dar_filtros($1) INTO rfiltros;
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN
        rusuario.idusuario = 25;
     END IF;
     cant = 0;
     OPEN cbancamov_ppal ;
     FETCH cbancamov_ppal  INTO rcbancamov_ppal ;
    
         
     WHILE found LOOP
          OPEN cbancamov; 
          FETCH cbancamov INTO rbancamov;
          WHILE found LOOP
                 RAISE NOTICE '>>>>>>>>ID movBanco movBanco (%)(%)',rcbancamov_ppal.idbancamovimiento,rbancamov.idbancamovimiento;
                 
                 -- 1 calculo el importe disponible del movimiento del banco ppal
                 SELECT  INTO disponible_ppal  ((abs(bmdebito) + abs(bmcredito)) - conciliacionbancaria_montoconciliado(idbancamovimiento::varchar,'{tipomov=banco}') )
                 FROM bancamovimiento
                 WHERE idbancamovimiento = rcbancamov_ppal.idbancamovimiento;
                 RAISE NOTICE 'disponible ppal banco(%)',disponible_ppal;
 
                 -- 1 calculo el importe disponible del movimiento del banco
                 SELECT  INTO disponible  ((abs(bmdebito) + abs(bmcredito)) - conciliacionbancaria_montoconciliado(idbancamovimiento::varchar,'{tipomov=banco}') )
                 FROM bancamovimiento
                 WHERE idbancamovimiento = rbancamov.idbancamovimiento;
                 
		 RAISE NOTICE 'disponible banco(%)',disponible;

                              
                monto_conciliar = disponible - disponible_ppal ;
    --Analizo si los mov del banco afectan uno al credito y otro al debito
   IF(rcbancamov_ppal.bmcredito>0 AND rbancamov.bmdebito=0 )or(rcbancamov_ppal.bmcredito=0 AND rbancamov.bmdebito>0) THEN
                 IF(disponible>0 AND disponible_ppal >0 ) THEN
                        IF(monto_conciliar<=0 ) THEN-- el monto de disponible_ppal es > pago
                               monto_real_conc = disponible;
                                RAISE NOTICE 'monto_real_conc = disponible (%)',monto_real_conc;
                         ELSE
                                monto_real_conc = disponible_ppal;
                                RAISE NOTICE 'monto_real_conc = monto_conciliar (%)',monto_real_conc;
                         END IF;

                         --- 2 - Creo el item de la conciliacion
                         IF(monto_real_conc>0) THEN 
                             /*reemplazo rcmovsiges.elcomprobante por rbancamov.bmnrocomprobante el 24-03-21 para cuando concilia mov de banco contra banco*/   
 INSERT INTO conciliacionbancariaitem(cbitablacomp,cbiclavecompsiges ,idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idusuario,cbiautomatica,cbiimporte,cbicomsiges)
                                 VALUES('bancamovimiento' ,rcbancamov_ppal.idbancamovimiento, rfiltros.idconciliacionbancaria,rfiltros.idcentroconciliacionbancaria,rbancamov.idbancamovimiento,rusuario.idusuario,FALSE,monto_real_conc,
rbancamov.bmnrocomprobante);
                        -- elidconitem = currval('conciliacionbancariaitem_idconciliacionbancariaitem_seq');
                         END IF;
                         cant = cant + 1;
                 END IF;--IF(disponible>0 AND disponible_ppal >0 )
END IF;-- IF(rcbancamov_ppal.bmcredito>0 AND rbancamov.bmdebito=0 )or(rcbancamov_ppal.bmcredito=0 AND rbancamov.bmdebito>0) 
  

          FETCH cbancamov INTO rbancamov;
          END LOOP;
          CLOSE cbancamov;
     FETCH cbancamov_ppal INTO rcbancamov_ppal;
     END LOOP;
     CLOSE cbancamov_ppal;

return cant;
END;
$function$
