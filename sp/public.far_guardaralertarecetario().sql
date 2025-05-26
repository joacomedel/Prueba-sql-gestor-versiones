CREATE OR REPLACE FUNCTION public.far_guardaralertarecetario()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
   	 
	ralertarectp RECORD;	 
        resp BOOLEAN;

BEGIN
 
SELECT INTO ralertarectp * FROM temp_recetariotpitemuso;
IF FOUND THEN 
  INSERT INTO recetariotp_alertado (idrecetariotpitem,idcentrorecetariotpitem,raobservacion,nrorecetario,centro,idusuariocreacion) 
	VALUES (ralertarectp.idrecetariotpitem,ralertarectp.idcentrorecetariotpitem,ralertarectp.observacionalerta,ralertarectp.nrorecetario,ralertarectp.centro,ralertarectp.idusuariocreacion);
END IF; 
    
    

return 'true';
END;$function$
