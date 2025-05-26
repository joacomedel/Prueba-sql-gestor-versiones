CREATE OR REPLACE FUNCTION public.asientogenericoimputacioncliente_crear(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

    registro RECORD;
     elasiento character varying;
     rimp RECORD;
     rminuta_imp RECORD;
     resp boolean;
     rfechapago RECORD;
     rfechadeuda RECORD;
  rfiltros  RECORD;
  
BEGIN
       
	 EXECUTE sys_dar_filtros($1) INTO rfiltros;
	--    RAISE NOTICE 'SYS::iddeuda, idpago, importe (%) (%) (%)',rfiltros.iddeuda , rfiltros.idpago,rfiltros.importeimp;
--	 RAISE NOTICE 'SYS:: rfiltros.importeimp y rimp.importeimp (%) (%) ',rfiltros.importeimp , rfiltros.importeimp;
--KR 08-09-22 si el pago es inferior a la puesta en produccion de esto(2022-08-29) no genero MP imputacion
--KR 14-09-22 solo se genera imputacion para afiliados adherentes (personas)
       SELECT INTO rfechapago * FROM ctactepagocliente NATURAL JOIN clientectacte ccc JOIN persona p ON ccc.nrocliente =p.nrodoc AND ccc.barra=p.tipodoc
       WHERE idpago= rfiltros.idpago AND idcentropago = rfiltros.idcentropago;
       IF FOUND AND rfechapago.fechamovimiento >='2022-08-29' THEN
--KR 15-09-22 verifico que la deuda sea despues de esta fecha x turismo, solo tenemos hoy el consumo de D.Torres realizado el 23-08-22 idcomprobantetiposasc =7 (TURISMO)
         SELECT INTO rfechadeuda * FROM ctactedeudacliente NATURAL JOIN  ctactedeudacliente_ext
         WHERE iddeuda= rfiltros.iddeuda AND idcentrodeuda = rfiltros.idcentrodeuda AND idcomprobantetipos =7 AND ccdccreacion >='2022-08-29' ;       
     --    IF NOT FOUND THEN
	--   IF (TG_OP = 'UPDATE') THEN -- se trata de una modificacion 
              RAISE NOTICE 'SYS:: es un UPDATE ';
	  
              SELECT INTO rimp * FROM ctactedeudapagocliente WHERE idctactedeudapagocliente = rfiltros.idctactedeudapagocliente AND idcentroctactedeudapagocliente=rfiltros.idcentroctactedeudapagocliente;   
              IF FOUND THEN 
                 
 -- La imputacion ya existia se verifica si hay cambios en el importe de la imputacion. Si es asi se debe anular la minuta de la imputacion actual
                 RAISE NOTICE 'SYS:: existe una rfiltros.importeimp y rimp.importeimp (%) (%) ',rfiltros.importeimp , rfiltros.importeimp;
                 SELECT INTO rminuta_imp *   FROM ctactedeudapagoclienteordenpago 
                                WHERE idctactedeudapagocliente = rfiltros.idctactedeudapagocliente AND idcentroctactedeudapagocliente=rfiltros.idcentroctactedeudapagocliente; 
                 IF FOUND THEN
		    RAISE NOTICE 'SYS:: existe una rminuta_imp.nroordenpago rminuta_imp.idcentroordenpago (%) (%) ',rminuta_imp.nroordenpago , rminuta_imp.idcentroordenpago;
                    SELECT INTO resp anularminutapago(rminuta_imp.nroordenpago, rminuta_imp.idcentroordenpago ); 
                 ELSE 
-- 110822 la imputacion no se registro a partir de una minuta por lo que se debe revertir el asiento de la imputacion
                    PERFORM asientogenerico_revertir(idasientogenerico*100+idcentroasientogenerico) 
                        FROM asientogenerico 
                        WHERE idcomprobantesiges = concat(concat(rfiltros.iddeuda,'|',rfiltros.idcentrodeuda,'|',rfiltros.idpago,'|',rfiltros.idcentropago ,'|',rfiltros.idctactedeudapagocliente,'|',rfiltros.idcentroctactedeudapagocliente))
                                              and idasientogenericocomprobtipo=9;
                 END IF;

              END IF;  
           END IF; 
           perform  contabilidad_generarminutaimputacioncliente (concat('{iddeuda=' ,rfiltros.iddeuda,',idcentrodeuda=', rfiltros.idcentrodeuda, ',idpago=', rfiltros.idpago, ' , idcentropago=',rfiltros.idcentropago, ',idctactedeudapagocliente=', rfiltros.idctactedeudapagocliente, ' , idcentroctactedeudapagocliente=',rfiltros.idcentroctactedeudapagocliente,'}'));
 
           -- corroboro si fue generada la minuta de imputacion
           SELECT INTO registro * FROM ctactedeudapagoclienteordenpago 
           WHERE  idctactedeudapagocliente = rfiltros.idctactedeudapagocliente AND idcentroctactedeudapagocliente=rfiltros.idcentroctactedeudapagocliente; 
           IF NOT FOUND THEN
              SELECT INTO elasiento asientogenericoimputacion_crear(concat(rfiltros.iddeuda,'|',rfiltros.idcentrodeuda,'|',rfiltros.idpago,'|',rfiltros.idcentropago ,'|',rfiltros.idctactedeudapagocliente,'|',rfiltros.idcentroctactedeudapagocliente));
           
      --     END IF;
     --    END IF;
     END IF;
    return'';
END;

$function$
