CREATE OR REPLACE FUNCTION public.guardainfopaseminutapagopresupuesto()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Genera una orden para pagar un conjunto de prestaciones.*/

DECLARE

--REGISTROS
    rinfopasedoc RECORD; 
    rpasedoc RECORD; 
	
BEGIN

 SELECT INTO rpasedoc * FROM temppasedocumento;
/*
 SELECT INTO rinfopasedoc * 
 FROM presupuestoitemordenpago NATURAL JOIN presupuestoitem NATURAL JOIN presupuesto JOIN solicitudpresupuesto USING  (idsolicitudpresupuesto, idcentrosolicitudpresupuesto) JOIN paseinfodocumento USING(idsolicitudpresupuesto, idcentrosolicitudpresupuesto)  JOIN pase USING(idpase, idcentropase) 
 WHERE iddocumento = rpasedoc.iddoc AND idcentrodocumento=rpasedoc.idcentro AND NOT nullvalue(nroordenpago);*/
 SELECT INTO rinfopasedoc *  FROM documento NATURAL JOIN documentoitem NATURAL JOIN recepcion NATURAL JOIN pase 
 WHERE iddocumento = rpasedoc.iddoc AND idcentrodocumento=rpasedoc.idcentro AND idsectororigen=rpasedoc.sectororigen AND not nullvalue(pafecharecepcion); 
--si lo encuentro es pq corresponde a una nota entonces guardo la info del pase

  IF FOUND THEN 
       UPDATE paseinfodocumento SET   pidmotivo = concat (pidmotivo, ' ',rpasedoc.motivo)
            WHERE idpase = rinfopasedoc.idpase AND idcentropase = rinfopasedoc.idcentropase;

        INSERT INTO paseinfodocumento(idpase, idcentropase,pidmotivo,idsectororigen,idsectordestino,idpersonaorigen,idpersonadestino)
        VALUES (currval('pase_idpase_seq'::regclass), centro(),rpasedoc.motivo,rpasedoc.sectororigen,rpasedoc.sectordestino,rpasedoc.idpersonaorigen, rpasedoc.idpersonadestino);

  END IF; 

    
   RETURN true;
END;
$function$
