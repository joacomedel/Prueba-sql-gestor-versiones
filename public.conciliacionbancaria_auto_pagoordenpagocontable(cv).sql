CREATE OR REPLACE FUNCTION public.conciliacionbancaria_auto_pagoordenpagocontable(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rusuario RECORD;
    cmovsiges CURSOR FOR SELECT * FROM  temp_movsiges WHERE tablacomp='pagoordenpagocontable'; -- temporal con los movimientos de siges que se desean conciliar
    clavecomp varchar;
    sqllaclave varchar;
    sql  varchar;
    cpagoopc refcursor;
    rpagoopc record;
    rinfopago record;
    rmovsiges record;
    rmovimientobanco  record;
    rparam record;
    elidconitem bigint;
    losparam  varchar;
    cant integer;
    saldo_sin_conciliar_siges double precision;
    monto  double precision;
    fechamodifopvasentada date;
BEGIN

     EXECUTE sys_dar_filtros($1) INTO rparam;
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN
        rusuario.idusuario = 25;
     END IF;
     cant = 0;

    fechamodifopvasentada='2023-11-01'::date;
    
     IF ( rparam.idbanco=41 AND rparam.cbfechahastamovimiento<=fechamodifopvasentada) THEN

            SELECT conciliacionbancaria_auto_mp_pagoordenpagocontable($1) INTO cant;


    ELSE        

     -- Recorro cada uno de los movimientos de siges que se desean conciliar automaticamente
      OPEN cmovsiges;
      FETCH  cmovsiges INTO rmovsiges;
      WHILE FOUND LOOP

                -- Obtengo el sql para buscar el pago a partir de la clave
                SELECT INTO sqllaclave  replace (rmovsiges.clavecomp,'|',' AND ');
              --  RAISE NOTICE 'rmovsiges.clavecomp(%)',rmovsiges.clavecomp;
                
                OPEN cpagoopc FOR EXECUTE concat('SELECT  * FROM pagoordenpagocontable WHERE ',sqllaclave);
                
                --OPEN cpagoopc FOR EXECUTE 'SELECT  * FROM pagoordenpagocontable WHERE idpagoordenpagocontable=2219 AND idcentropagoordenpagocontable=1';
                FETCH  cpagoopc INTO rpagoopc;
                WHILE FOUND LOOP
                      saldo_sin_conciliar_siges = rmovsiges.monto -  conciliacionbancaria_montoconciliado(rmovsiges.clavecomp,concat('{tipomov=siges,idcbitipo=1',',tabla=pagoordenpagocontable, nrocuentac=', rparam.nrocuentac ,'}')::varchar);
                      
                      --- RAISE NOTICE 'SQL QUE EECUTA (%)',concat('SELECT  * FROM pagoordenpagocontable WHERE ',sqllaclave);
                      --- Verifico si se proesaron los datos del pago
                      SELECT INTO rinfopago *
                      FROM pagoordenpagocontable
                      LEFT JOIN ordenpagocontablebancatransferencia USING (idcentropagoordenpagocontable, idpagoordenpagocontable)
                      LEFT JOIN bancatransferencia USING (idbancatransferencia)
                      LEFT JOIN bancaoperacion USING (idbancaoperacion)
                      WHERE  idpagoordenpagocontable = rpagoopc.idpagoordenpagocontable
                             AND  idcentropagoordenpagocontable = rpagoopc.idcentropagoordenpagocontable
                             AND  not nullvalue(idbancatransferencia)  ;

                      IF (FOUND AND saldo_sin_conciliar_siges >0) THEN
                            -- busco el movimiento dentro de los movimientos del banco que no han sido conciliados yse correspondan con salidas del banco >0
                            SELECT INTO rmovimientobanco (bmdebito - conciliacionbancaria_montoconciliado(idbancamovimiento::varchar ,concat('{tipomov=banco}')::varchar) ) as saldo_sin_conciliar_banco  , *
                            FROM temp_bancamovimiento
                            WHERE
                                  (bmdebito - conciliacionbancaria_montoconciliado(idbancamovimiento::varchar ,concat('{tipomov=banco}')::varchar ) ) >0 -- Queda saldo para conciliar
                                  AND abs(bmdebito-rinfopago.popmonto) < 1 -- el monto del banco coincide con el del movimiento
                                  AND bmfecha = rmovsiges.fechacompr; -- la fecha del comprobante debe coincidir con la fecha del banco
 --   AND ((bmnrocomprobante = rinfopago.bonrosecuencia OR (bmnrocomprobante::bigint)-1 = rinfopago.bonrosecuencia) -- si es una consiliacion automatica--   ) 

                            IF ( FOUND AND (rmovimientobanco.saldo_sin_conciliar_banco >0 ) ) THEN
                                     -- se encuentra procesada la info del pago
                                     -- es posible realizar una conciliacion automatica
                                     
                                     monto = saldo_sin_conciliar_siges - rmovimientobanco.saldo_sin_conciliar_banco;
                                     IF ( monto >=0 ) THEN
                                          monto =  rmovimientobanco.saldo_sin_conciliar_banco;
                                     ELSE
                                         monto = saldo_sin_conciliar_siges;
                                     END IF;
                                     INSERT INTO conciliacionbancariaitem(cbitablacomp,cbiclavecompsiges ,idconciliacionbancaria,idcentroconciliacionbancaria,idbancamovimiento,idusuario,cbiautomatica,cbiimporte,cbicomsiges)
                                     VALUES(rmovsiges.tablacomp ,rmovsiges.clavecomp, rparam.idconciliacionbancaria::bigint ,rparam.idcentroconciliacionbancaria::integer,rmovimientobanco.idbancamovimiento,rusuario.idusuario,true,monto,rmovsiges.elcomprobante);
                                     cant = cant +1;
                            END IF;
                    END IF;

             FETCH  cpagoopc INTO rpagoopc;
             END LOOP;
             CLOSE cpagoopc;
      FETCH  cmovsiges INTO rmovsiges;
      END LOOP;

     CLOSE cmovsiges;
      RAISE NOTICE 'ESTO TIENE CANTIDAD  (%)',cant;


    END IF;

return cant;
END;
$function$
