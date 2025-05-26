CREATE OR REPLACE FUNCTION public.guardainfopasenota()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--REGISTROS
    rinfopasedoc RECORD; 
    rpasedoc RECORD; 

--VARIABLES
   vnroordenpago BIGINT;
   vidcentroordenpago INTEGER; 
 
BEGIN

 SELECT INTO rpasedoc * FROM temppasedocumento;

 SELECT INTO rinfopasedoc *  FROM documento NATURAL JOIN documentoitem NATURAL JOIN recrecetario NATURAL JOIN pase 
 WHERE iddocumento = rpasedoc.iddoc AND idcentrodocumento=rpasedoc.idcentro AND idsectororigen=rpasedoc.sectororigen AND not nullvalue(pafecharecepcion); 
--si lo encuentro es pq corresponde a una nota entonces guardo la info del pase

  IF FOUND THEN 
       IF not existecolumtemp('temppasedocumento', 'nroordenpago') THEN 
           vnroordenpago=null;
           vidcentroordenpago=null;
       ELSE 
           vnroordenpago=rpasedoc.nroordenpago;
           vidcentroordenpago=rpasedoc.idcentroordenpago;
       END IF;
      
       UPDATE paseinfodocumento SET pidultimo = FALSE WHERE idpase = rinfopasedoc.idpase AND idcentropase= rinfopasedoc.idcentropase;
        INSERT INTO paseinfodocumento(idpase, idcentropase,pidmotivo,nroordenpago,idcentroordenpago,pidultimo)
        VALUES (currval('pase_idpase_seq'::regclass), centro(),rpasedoc.motivo,vnroordenpago, vidcentroordenpago, TRUE);
       UPDATE paseinfodocfichamedicainfomedicamento SET 	idpaseinfodocumento= currval('paseinfodocfichamedicainfomed_idpaseinfodocfichamedicainfom_seq'::regclass),
                                                        	idcentropaseinfodocumento	 = centro() 
       WHERE iddocumento=rinfopasedoc.iddocumento	 and idcentrodocumento = rinfopasedoc.idcentrodocumento ;-- AND idcentropase= rinfopasedoc.idcentropase;   

  END IF; 

    
   RETURN true;
END;
$function$
