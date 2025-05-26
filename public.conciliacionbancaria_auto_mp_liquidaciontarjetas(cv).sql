CREATE OR REPLACE FUNCTION public.conciliacionbancaria_auto_mp_liquidaciontarjetas(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/****/
DECLARE

    rusuario RECORD;

    cliquidaciontarjeta refcursor;
    rliquidaciontarjeta record;
    cmovsiges CURSOR FOR SELECT * FROM  temp_movsiges; -- temporal con los movimientos de siges que se desean conciliar
    clavecomp varchar;
    cmovbancomp refcursor;

    rmovsiges record;
    rmovimientobanco  record;
    rmovbancomp record;
    rmovaux record;
    rparam record;
    elidconitem bigint;
    losparam  varchar;
    cant integer;
    cantFila integer;
    monto  double precision;
    cantprocesados integer;
    auxDni varchar;

BEGIN

     cantprocesados = 0;
     EXECUTE sys_dar_filtros($1) INTO rparam;
     --{manual=false, idcentroconciliacionbancaria=1, idconciliacionbancaria=10}
     -- SELECT INTO rparam false as manual, 1 as  idcentroconciliacionbancaria , 10 as idconciliacionbancaria;
     SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
     IF NOT FOUND THEN
        rusuario.idusuario = 25;
     END IF;
     cant = 0;

     /*obtengo los grupos de SIGES que tienen el mismo idoperacion */
     IF (not iftableexistsparasp('temp_movsiges_aux') ) THEN 
         CREATE TEMP TABLE temp_movsiges_aux AS SELECT * FROM temp_movsiges; -- resguardo la tabla con los movimientos de SIGES
     END IF;
     IF (not iftableexistsparasp('temp_bancamovimiento_aux') ) THEN 
         CREATE TEMP TABLE temp_bancamovimiento_aux AS SELECT * FROM temp_bancamovimiento; -- resguardo la tabla con los movimientos del banco
     END IF;

--
     OPEN cliquidaciontarjeta FOR SELECT trim(replace(split_part(ltobservacion,'-',1),'Comercio ','')) as elcomercio,idliquidaciontarjeta,idcentroliquidaciontarjeta, ltfechapago ,ltimporteliquidaciontarjeta
     FROM (
            SELECT split_part(split_part(temp_movsiges_aux.clavecomp, '|',1),'=',2)::bigint as idliquidaciontarjeta , split_part( split_part(temp_movsiges_aux.clavecomp, '|',2) ,'=',2)::integer  as idcentroliquidaciontarjeta
            FROM temp_movsiges_aux
            WHERE tablacomp='liquidaciontarjeta'
     )as T
     NATURAL JOIN liquidaciontarjeta
     GROUP BY trim(replace(split_part(ltobservacion,'-',1),'Comercio ','')),idliquidaciontarjeta,idcentroliquidaciontarjeta,ltfechapago ,ltimporteliquidaciontarjeta;

     FETCH cliquidaciontarjeta INTO rliquidaciontarjeta;
     WHILE FOUND LOOP
           --- Repetir por cada idbancaoperacion encontrada
           
           INSERT INTO temp_movsiges (elcomprobante ,tablacomp  ,clavecomp  ,fechacompr ,monto  ,impconc)  (
               SELECT T.elcomprobante   ,T.tablacomp    ,T.clavecomp    ,T.fechacompr   ,T.monto    ,T.impconc
               FROM (
                     SELECT split_part(split_part(temp_movsiges_aux.clavecomp, '|',1),'=',2)::bigint as idliquidaciontarjeta , split_part( split_part(temp_movsiges_aux.clavecomp, '|',2) ,'=',2)::integer  as idcentroliquidaciontarjeta,*
                     FROM temp_movsiges_aux
                     WHERE tablacomp='liquidaciontarjeta'
               )as T
               NATURAL JOIN liquidaciontarjeta
               WHERE  idcentroliquidaciontarjeta = rliquidaciontarjeta.idcentroliquidaciontarjeta
                      AND idliquidaciontarjeta = rliquidaciontarjeta.idliquidaciontarjeta
           );

        OPEN cmovbancomp FOR SELECT * FROM  temp_bancamovimiento; 

        FETCH cmovbancomp INTO rmovbancomp;
        WHILE FOUND LOOP
                
                DELETE FROM temp_bancamovimiento;

                IF (POSITION('Pago aporte' IN rmovbancomp.bmconcepto) > 0) THEN

                    /* Si es un Recibo */

                    /* En el caso de que sea un Recibo me fijo si coincide con aluno de dentro de la liquidacion*/
                        
                        SELECT INTO rmovaux *
                        FROM liquidaciontarjeta AS lt
                            JOIN  liquidaciontarjetaitem lti ON (lt.idliquidaciontarjeta = lti.idliquidaciontarjeta)
                            LEFT JOIN recibocupon USING (idrecibocupon)
                            LEFT JOIN recibo USING (idrecibo)
                        WHERE lt.idliquidaciontarjeta = rliquidaciontarjeta.idliquidaciontarjeta  
                            AND importerecibo = rmovbancomp.bmcredito  
                            AND fecharecibo ilike concat('%', rmovbancomp.bmfecha ,'%' )  ; 
                        

                        IF FOUND THEN
                        /* Si el movimiento del banco coincide con un item de la conciliacion, se agrega a la tabla temp_bancamovimiento que es la que se usa para conciliar */

                        --RAISE NOTICE 'DENTRO DEL FOUND : rmovbancomp (%)',rmovbancomp;

                        INSERT INTO temp_bancamovimiento(bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito ) 
                        VALUES (rmovbancomp.bmusuario,rmovbancomp.bmfecha,rmovbancomp.idbancamovimiento,rmovbancomp.idcentroconciliacionbancaria,rmovbancomp.idconciliacionbancaria,rmovbancomp.bmconcepto,rmovbancomp.bmcodigo,rmovbancomp.bmsaldo,rmovbancomp.bmingreso,rmovbancomp.bmdebito,rmovbancomp.bmnrocomprobante,rmovbancomp.bmcredito );

                        END IF;

                ELSE 
                    IF (POSITION('FAC - Factura' IN rmovbancomp.bmconcepto) > 0) THEN

                    /* Si es una Factura */   

                        SELECT into auxDni trim(split_part(rmovbancomp.bmconcepto,' - ',5)::varchar );

                        SELECT INTO rmovaux *
                        FROM    liquidaciontarjeta AS lt
                                JOIN  liquidaciontarjetaitem lti ON (lt.idliquidaciontarjeta = lti.idliquidaciontarjeta)
                                JOIN facturaventacupon fvc USING (idfacturacupon, centro, nrofactura, tipocomprobante, nrosucursal, tipofactura)
                                JOIN facturaventa fv USING (nrofactura, tipocomprobante, nrosucursal, tipofactura)
                        WHERE   lt.idliquidaciontarjeta = rliquidaciontarjeta.idliquidaciontarjeta
                                --AND fv.nrodoc=auxDni 
                                AND fv.importeefectivo= rmovbancomp.bmcredito 
                                AND fv.fechaemision= rmovbancomp.bmfecha ;


                        IF FOUND THEN
                        /* Si el movimiento del banco coincide con un item de la conciliacion, se agrega a la tabla temp_bancamovimiento que es la que se usa para conciliar */

                            --RAISE NOTICE 'DENTRO DEL FOUND FACTURAAAAAAAAA : rmovbancomp (%)',rmovbancomp;

                            INSERT INTO temp_bancamovimiento(bmusuario,bmfecha,idbancamovimiento,idcentroconciliacionbancaria,idconciliacionbancaria,bmconcepto,bmcodigo,bmsaldo,bmingreso,bmdebito,bmnrocomprobante,bmcredito ) 
                            VALUES (rmovbancomp.bmusuario,rmovbancomp.bmfecha,rmovbancomp.idbancamovimiento,rmovbancomp.idcentroconciliacionbancaria,rmovbancomp.idconciliacionbancaria,rmovbancomp.bmconcepto,rmovbancomp.bmcodigo,rmovbancomp.bmsaldo,rmovbancomp.bmingreso,rmovbancomp.bmdebito,rmovbancomp.bmnrocomprobante,rmovbancomp.bmcredito );

                        END IF;
                    
                    END IF;

                END IF;

                SELECT INTO cant  conciliacionbancaria_conciliarmovimientos(concat('{manual=false, idcentroconciliacionbancaria=',rparam.idcentroconciliacionbancaria,', idconciliacionbancaria=',rparam.idconciliacionbancaria,', nrocuentac=', rparam.nrocuentac ,'}'));
                cantprocesados = cantprocesados + cant;


        FETCH cmovbancomp INTO rmovbancomp;
        END LOOP;
        CLOSE cmovbancomp;



      FETCH cliquidaciontarjeta INTO rliquidaciontarjeta;
      END LOOP;
      CLOSE cliquidaciontarjeta;

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
