CREATE OR REPLACE FUNCTION public.asientogenericoimputacioncliente_crear_tr()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$DECLARE
      registro RECORD;
     elasiento character varying;
     rimp RECORD;
     rminuta_imp RECORD;
     resp boolean;
     rfechapago RECORD;
     rfechadeuda RECORD;
BEGIN
	    RAISE NOTICE 'SYS::iddeuda, idpago, importe (%) (%) (%)',NEW.iddeuda , NEW.idpago,NEW.importeimp;
--KR 08-09-22 si el pago es inferior a la puesta en produccion de esto(2022-08-29) no genero MP imputacion
--KR 14-09-22 solo se genera imputacion para afiliados adherentes (personas)
       SELECT INTO rfechapago * FROM ctactepagocliente NATURAL JOIN clientectacte ccc JOIN persona p ON ccc.nrocliente =p.nrodoc AND ccc.barra=p.tipodoc
       WHERE idpago= NEW.idpago AND idcentropago = NEW.idcentropago;
       IF FOUND AND rfechapago.fechamovimiento >='2022-08-29' THEN
--KR 15-09-22 verifico que la deuda sea despues de esta fecha x turismo, solo tenemos hoy el consumo de D.Torres realizado el 23-08-22 idcomprobantetiposasc =7 (TURISMO)
         SELECT INTO rfechadeuda * FROM ctactedeudacliente NATURAL JOIN  ctactedeudacliente_ext
         WHERE iddeuda= NEW.iddeuda AND idcentrodeuda = NEW.idcentrodeuda AND idcomprobantetipos =7 AND ccdccreacion >='2022-08-29' ;       
       -- VAS 090623  IF NOT FOUND THEN
        
       IF (TG_OP = 'UPDATE') THEN -- se trata de una modificacion 
              RAISE NOTICE 'SYS:: es un UPDATE ';
      
              SELECT INTO rimp * 
              FROM ctactedeudapagocliente 
              WHERE idctactedeudapagocliente = NEW.idctactedeudapagocliente 
              AND idcentroctactedeudapagocliente=NEW.idcentroctactedeudapagocliente;   
              IF FOUND THEN 
                 
 -- La imputacion ya existia se verifica si hay cambios en el importe de la imputacion. Si es asi se debe anular la minuta de la imputacion actual
                 RAISE NOTICE 'SYS:: existe una NEW.importeimp y rimp.importeimp (%) (%) ',NEW.importeimp , rimp.importeimp;
                 -- BelenA 04/04/24  Modifico ligeramente la consulta para que busque la minuta de imputacion que no esta anulada
                 -- Ya que pudiendo desimputar y volver a imputar, termina teniendo más de una minuta de imputacion
                 SELECT INTO rminuta_imp *   
                 FROM ctactedeudapagoclienteordenpago                  
                    JOIN ordenpago USING (nroordenpago, idcentroordenpago)
                    JOIN cambioestadoordenpago USING (nroordenpago, idcentroordenpago)
                 
                 WHERE idctactedeudapagocliente = NEW.idctactedeudapagocliente 
                 AND idcentroctactedeudapagocliente=NEW.idcentroctactedeudapagocliente
                 AND nullvalue(ceopfechafin) AND idtipoestadoordenpago!=4; 

                 IF FOUND THEN
            RAISE NOTICE 'SYS:: existe una rminuta_imp.nroordenpago rminuta_imp.idcentroordenpago (%) (%) ',rminuta_imp.nroordenpago , rminuta_imp.idcentroordenpago;
                    SELECT INTO resp anularminutapago(rminuta_imp.nroordenpago, rminuta_imp.idcentroordenpago ); 
                 ELSE 
-- 110822 la imputacion no se registro a partir de una minuta por lo que se debe revertir el asiento de la imputacion
                    PERFORM asientogenerico_revertir(idasientogenerico*100+idcentroasientogenerico) 
                        FROM asientogenerico 
                        WHERE idcomprobantesiges = concat(concat(NEW.iddeuda,'|',NEW.idcentrodeuda,'|',NEW.idpago,'|',NEW.idcentropago ,'|',NEW.idctactedeudapagocliente,'|',NEW.idcentroctactedeudapagocliente))
                                              and idasientogenericocomprobtipo=9;
                 END IF;

              END IF;  
           END IF; 
           perform  contabilidad_generarminutaimputacioncliente (concat('{iddeuda=' ,NEW.iddeuda,',idcentrodeuda=', NEW.idcentrodeuda, ',idpago=', NEW.idpago, ' , idcentropago=',NEW.idcentropago, ',idctactedeudapagocliente=', NEW.idctactedeudapagocliente, ' , idcentroctactedeudapagocliente=',NEW.idcentroctactedeudapagocliente,'}'));
 
           -- corroboro si fue generada la minuta de imputacion
           SELECT INTO registro * FROM ctactedeudapagoclienteordenpago 
           WHERE  idctactedeudapagocliente = NEW.idctactedeudapagocliente AND idcentroctactedeudapagocliente=NEW.idcentroctactedeudapagocliente; 
           IF NOT FOUND THEN
              SELECT INTO elasiento asientogenericoimputacion_crear(concat(NEW.iddeuda,'|',NEW.idcentrodeuda,'|',NEW.idpago,'|',NEW.idcentropago ,'|',NEW.idctactedeudapagocliente,'|',NEW.idcentroctactedeudapagocliente));
           
           END IF;
        -- VAS 090623  END IF;
     END IF;
    return NEW;
END;

$function$
