CREATE OR REPLACE FUNCTION public.ficha_medica_paseinfodocfichamedicainfomedicamento()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--REGISTROS
    rpidfmim RECORD; 
    rpasedoc RECORD; 

--VARIABLES
   vnroordenpago BIGINT;
   vidcentroordenpago INTEGER; 
 
BEGIN

 IF iftableexistsparasp('temppaseinfodocfichamedicainfomedicamento') THEN 

     SELECT INTO rpidfmim * FROM temppaseinfodocfichamedicainfomedicamento;

     IF nullvalue(rpidfmim.idpaseinfodocfichamedicainfomedicamento) THEN 
        INSERT INTO paseinfodocfichamedicainfomedicamento(idpaseinfodocumento,idcentropaseinfodocumento,iddocumento,idcentrodocumento,idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento)             
        SELECT idpaseinfodocumento,idcentropaseinfodocumento,iddocumento,idcentrodocumento,idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento FROM temppaseinfodocfichamedicainfomedicamento;  

     ELSE 
        UPDATE paseinfodocfichamedicainfomedicamento SET idfichamedicainfomedicamento= T.idfichamedicainfomedicamento,   
                      idcentrofichamedicainfomedicamento =T.idcentrofichamedicainfomedicamento ,
                      idpaseinfodocumento =T.idpaseinfodocumento ,
                      idcentropaseinfodocumento =T.idcentropaseinfodocumento, 
                      iddocumento =T.iddocumento ,
                      idcentrodocumento =T.idcentrodocumento 
        FROM (   SELECT idpaseinfodocumento,idcentropaseinfodocumento,iddocumento,idcentrodocumento,idfichamedicainfomedicamento,idcentrofichamedicainfomedicamento,idpaseinfodocfichamedicainfomedicamento,idcentropaseinfodocfichamedicainfomedicamento
		FROM temppaseinfodocfichamedicainfomedicamento ) AS T  
		WHERE paseinfodocfichamedicainfomedicamento.idpaseinfodocfichamedicainfomedicamento=T.idpaseinfodocfichamedicainfomedicamento AND  
                paseinfodocfichamedicainfomedicamento.idcentropaseinfodocfichamedicainfomedicamento=T.idcentropaseinfodocfichamedicainfomedicamento;


     END IF; 
 END IF; 



    
   RETURN '';
END;
$function$
