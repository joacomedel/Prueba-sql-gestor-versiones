CREATE OR REPLACE FUNCTION public.conciliacionbancaria_auto_mp_minuta(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rusuario RECORD;
    cmovimientossiges CURSOR FOR SELECT * FROM  temp_movsiges WHERE tablacomp='ordenpago'; -- temporal con los movimientos de siges que se desean conciliar
    clavecomp varchar;
    auxcomprob varchar;
    cmovbancomp refcursor;
    rmovbancomp record;
    rinfopago record;
    rmovsiges record;
    rmovimientobanco  record;
    rparam record;
    elidconitem bigint;
    concept  varchar;
    cant integer;
    cantprocesados integer;
    saldo_sin_conciliar_siges double precision;
    monto  double precision;
BEGIN

     EXECUTE sys_dar_filtros($1) INTO rparam;
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN
        rusuario.idusuario = 25;
     END IF;
     cantprocesados = 0;

     /*obtengo los grupos de SIGES que tienen el mismo idoperacion */
     IF (not iftableexistsparasp('temp_movsiges_aux') ) THEN 
         CREATE TEMP TABLE temp_movsiges_aux AS SELECT * FROM temp_movsiges; -- resguardo la tabla con los movimientos de SIGES
     END IF;
     IF (not iftableexistsparasp('temp_bancamovimiento_aux') ) THEN 
         CREATE TEMP TABLE temp_bancamovimiento_aux AS SELECT * FROM temp_bancamovimiento; -- resguardo la tabla con los movimientos del banco
     END IF;


        OPEN cmovbancomp FOR SELECT * FROM  temp_bancamovimiento; 
        FETCH cmovbancomp INTO rmovbancomp;
        WHILE FOUND LOOP

            DELETE FROM temp_bancamovimiento;

            INSERT INTO temp_bancamovimiento(bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito ) 
            VALUES (rmovbancomp.bmusuario,rmovbancomp.bmfecha,rmovbancomp.idbancamovimiento,rmovbancomp.idcentroconciliacionbancaria,rmovbancomp.idconciliacionbancaria,rmovbancomp.bmconcepto,rmovbancomp.bmcodigo,rmovbancomp.bmsaldo,rmovbancomp.bmingreso,rmovbancomp.bmdebito,rmovbancomp.bmnrocomprobante,rmovbancomp.bmcredito );

            auxcomprob=rmovbancomp.bmnrocomprobante::varchar;

                    SELECT INTO rmovsiges *
                    FROM temp_movsiges_aux
                    WHERE (POSITION(auxcomprob IN detalle) > 0) AND tablacomp='ordenpago' AND
                    impconc = rmovbancomp.bmdebito  AND fechacompr = rmovbancomp.bmfecha ; 

                    IF FOUND THEN
    
                        DELETE FROM temp_movsiges;

                        DELETE FROM temp_movsiges_aux where (POSITION(auxcomprob IN detalle) > 0) AND tablacomp='ordenpago' AND impconc = rmovbancomp.bmdebito  AND fechacompr = rmovbancomp.bmfecha ; 

                        INSERT INTO temp_movsiges (elcomprobante  ,tablacomp  ,clavecomp  ,fechacompr ,monto  ,impconc) VALUES (
                        rmovsiges.elcomprobante   ,rmovsiges.tablacomp    ,rmovsiges.clavecomp    ,rmovsiges.fechacompr   ,rmovsiges.monto    ,rmovsiges.impconc ) ;

                        SELECT INTO cant  conciliacionbancaria_conciliarmovimientos(concat('{manual=false, idcentroconciliacionbancaria=',rparam.idcentroconciliacionbancaria,', idconciliacionbancaria=',rparam.idconciliacionbancaria,', nrocuentac=', rparam.nrocuentac ,'}'));
                        cantprocesados = cantprocesados + cant;
    
                    END IF;


            FETCH cmovbancomp INTO rmovbancomp;
            END LOOP;
            CLOSE cmovbancomp;



     -- Restauro las temporales
      DELETE FROM temp_bancamovimiento;
      DELETE FROM temp_movsiges;

      INSERT INTO temp_bancamovimiento (bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito )(
                 SELECT bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito
                 FROM temp_bancamovimiento_aux );

      INSERT INTO temp_movsiges (elcomprobante  ,tablacomp  ,clavecomp  ,fechacompr ,monto  ,impconc)  (
               SELECT a.elcomprobante   ,a.tablacomp    ,a.clavecomp    ,a.fechacompr   ,a.monto    ,a.impconc
               FROM temp_movsiges_aux as a ) ;


return cantprocesados;
END;
$function$
