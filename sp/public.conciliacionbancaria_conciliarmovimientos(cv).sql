CREATE OR REPLACE FUNCTION public.conciliacionbancaria_conciliarmovimientos(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
    rusuario RECORD;
    cbancamov CURSOR FOR SELECT * FROM  temp_bancamovimiento; -- temporal con los movimientos de la banca que se desean conciliar
    cmovsiges CURSOR FOR SELECT * FROM  temp_movsiges; -- temporal con los comprobantes de SIGES que se desean conciliar
    rbancamov record;
    rcmovsiges record;
    resp boolean;
    cant integer;
    rfiltros RECORD;info varchar;
    disponible double precision;
    monto_conciliar  double precision;
    monto_real_conc double precision;
    imp_sin_conc_siges  double precision;
    elidconitem bigint;
     parametros character varying;
resp_bb character varying;
cbauto boolean ;
BEGIN
     EXECUTE sys_dar_filtros($1) INTO rfiltros;
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN
        rusuario.idusuario = 25;
     END IF;
     cant = 0;
     OPEN cmovsiges;
     FETCH cmovsiges INTO rcmovsiges;
     IF (NOT FOUND or nullvalue(rcmovsiges.monto)) THEN  -- no hay movimeintos de siges
                        
   --llamar SP que concilia movimientos de banco entre si
    --  RAISE NOTICE '>>>>>>>>Llamada al conciliacionbancaria_conciliarmovimientosbanco (%)(%)',conciliacionbancaria_conciliarmovimientosbanco($1);
   RAISE NOTICE '>>>>>>>>Llamada al conciliacionbancaria_conciliarmovimientosbanco  (%)',conciliacionbancaria_conciliarmovimientosbanco($1);
   
                SELECT INTO resp_bb conciliacionbancaria_conciliarmovimientosbanco($1);

                cant=44;

     ELSE 
           -- verifico si es un comprobante de gasto  lo que se desea conciliar
                IF(rcmovsiges.tablacomp = 'compGasto') THEN
         parametros = concat( '{idconciliacionbancaria=',rfiltros.idconciliacionbancaria,',idcentroconciliacionbancaria=',rfiltros.idcentroconciliacionbancaria,
                            ',elnroregistro =',  split_part(rcmovsiges.clavecomp, '|', 1), ', elanio =', split_part(rcmovsiges.clavecomp, '|', 2),'}' );
         

 ---VAS ESTO GENERA LA DUPLICACION ??  RAISE NOTICE '>>>>>>>>Llamada al conciliacionbancaria_compgasto_generaropc(%)', conciliacionbancaria_compgasto_generaropc(parametros);

 RAISE NOTICE '>>>>>>>>Llamada al conciliacionbancaria_compgasto_generaropc(%)',parametros;

SELECT INTO resp conciliacionbancaria_compgasto_generaropc(parametros);
         CLOSE cmovsiges;
         OPEN cmovsiges;
         FETCH cmovsiges INTO rcmovsiges;
     END IF;
         
              WHILE found LOOP -- por cada movimiento de siges
                 if  not  iftableexists('temp_bancamovimiento') then 
                   
                   --IF (NOT FOUND or nullvalue(rbancamov.monto)) THEN  -- no hay movimientos del banco
                  INSERT INTO conciliacionbancariaitem(cbitablacomp,cbiclavecompsiges ,idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idusuario,cbiautomatica,cbiimporte,cbicomsiges,cbicomsigesdetalle)
                                 VALUES(rcmovsiges.tablacomp ,rcmovsiges.clavecomp, rfiltros.idconciliacionbancaria,rfiltros.idcentroconciliacionbancaria,null,rusuario.idusuario,FALSE,rcmovsiges.monto,rcmovsiges.elcomprobante,rcmovsiges.detalle);
else
                     OPEN cbancamov; 
                     FETCH cbancamov INTO rbancamov;
                     WHILE found LOOP
                     RAISE NOTICE '>>>>>>>>ID movBanco movSiges (%)(%)',rbancamov.idbancamovimiento,rcmovsiges.clavecomp;
   
                 -- 1 calculo el importe disponible del movimiento del banco
                 SELECT  INTO disponible  ((abs(bmdebito) + abs(bmcredito)) - conciliacionbancaria_montoconciliado(idbancamovimiento::varchar,concat('{tipomov=banco}')::varchar ))
                 FROM bancamovimiento
                 WHERE idbancamovimiento = rbancamov.idbancamovimiento;
                 
                 RAISE NOTICE 'disponible banco(%)',disponible;
/*Vivi el 30102020 dijo q al conciliar mov siges se debe sumar en lugar de restar*/
/*Dani cambio el 2021-12-23 para que haga la resta  pq al conciliar 1 mov siges con 1 mov banco de mayor importe  no dejaba el saldo como pendiente de conciliar en el banco*/

                 imp_sin_conc_siges = rcmovsiges.monto-conciliacionbancaria_montoconciliado(rcmovsiges.clavecomp,concat('{','tipomov=siges,tabla=',rcmovsiges.tablacomp,', nrocuentac=', rfiltros.nrocuentac ,'}')::varchar) ;
                 
                 RAISE NOTICE 'imp_sin_conc_siges(%)',imp_sin_conc_siges;
                 monto_conciliar = disponible - imp_sin_conc_siges ;

                 IF(disponible>0) THEN
                        IF(monto_conciliar<0 or monto_conciliar=0 ) THEN-- el monto de siges es > pago
                               monto_real_conc = disponible;
                                RAISE NOTICE 'monto_real_conc = disponible (%)',monto_real_conc;
                         ELSE
                                monto_real_conc = imp_sin_conc_siges;
                                RAISE NOTICE 'monto_real_conc = monto_conciliar (%)',monto_real_conc;
                         END IF;

                         --- 2 - Creo el item de la conciliacion
                         IF(monto_real_conc>0) THEN 

                                 IF not nullvalue(rfiltros.manual) THEN
                                        cbauto = rfiltros.manual;
                                 ELSE 
                                        cbauto = FALSE;
                                 END IF;

                             /*  VAS comenta 13/06/22  INSERT INTO conciliacionbancariaitem(cbitablacomp,cbiclavecompsiges ,idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idusuario,cbiautomatica,cbiimporte,cbicomsiges,cbicomsigesdetalle  )
                                 VALUES(rcmovsiges.tablacomp ,rcmovsiges.clavecomp, rfiltros.idconciliacionbancaria,rfiltros.idcentroconciliacionbancaria,rbancamov.idbancamovimiento,rusuario.idusuario,cbauto,monto_real_conc,rcmovsiges.elcomprobante,rcmovsiges.detalle);*/

                                 /* VAS comenta 2/11/23                               INSERT INTO conciliacionbancariaitem(cbitablacomp,cbiclavecompsiges ,idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idusuario,cbiautomatica,cbiimporte,cbicomsiges,cbicomsigesdetalle,idasientogenerico,  idcentroasientogenerico)
                                 VALUES(rcmovsiges.tablacomp ,rcmovsiges.clavecomp, rfiltros.idconciliacionbancaria,rfiltros.idcentroconciliacionbancaria,rbancamov.idbancamovimiento,rusuario.idusuario,cbauto,monto_real_conc,rcmovsiges.elcomprobante,rcmovsiges.detalle,rcmovsiges.idasientogenerico,  rcmovsiges.idcentroasientogenerico);
*/


INSERT INTO conciliacionbancariaitem(cbitablacomp,cbiclavecompsiges ,idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idusuario,cbiautomatica,cbiimporte,cbicomsiges,cbicomsigesdetalle,idasientogenerico,  idcentroasientogenerico,nrocuentacorigen)
                                 VALUES(rcmovsiges.tablacomp ,rcmovsiges.clavecomp, rfiltros.idconciliacionbancaria,rfiltros.idcentroconciliacionbancaria,rbancamov.idbancamovimiento,rusuario.idusuario,cbauto,monto_real_conc,rcmovsiges.elcomprobante,rcmovsiges.detalle,rcmovsiges.idasientogenerico,  rcmovsiges.idcentroasientogenerico,rcmovsiges.nrocuentacorigen );



---  VAS 09-06-22 agrega VAS para guardar la referencia al asiento del comprobante
                        -- elidconitem = currval('conciliacionbancariaitem_idconciliacionbancariaitem_seq');
                         END IF;
                         cant = cant + 1;
                 END IF;
          FETCH cbancamov INTO rbancamov;
          END LOOP;
          CLOSE cbancamov;
 END IF;--no hay mov del banco 
    FETCH cmovsiges INTO rcmovsiges;
     END LOOP;
    END IF ;  -- hay movimientos siges
     CLOSE cmovsiges;

return cant;
END;
$function$
