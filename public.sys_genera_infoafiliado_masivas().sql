CREATE OR REPLACE FUNCTION public.sys_genera_infoafiliado_masivas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	
	cursorr refcursor;	
	runrecord RECORD;
	respuesta boolean;
        
   
BEGIN

CREATE TEMP TABLE temp_afiliaciones_gestionalertasafiliado AS  ( SELECT * FROM infoafiliado NATURAL JOIN infoafiliado_dondemostra LIMIT 0);

OPEN cursorr FOR SELECT * FROM w_afiliados_notificados where idinfoafiliado=0; --LIMIT 10;
FETCH cursorr INTO runrecord;
WHILE FOUND LOOP

INSERT INTO temp_afiliaciones_gestionalertasafiliado (iafechaini,iagrupofamiliar,iatexto,tipodoc,nrodoc,iafechafin,idinfoafiliadoquienmuestra)  
VALUES('2019-07-21',true,'De acuerdo a los registros en sistema, usted no ha realizado el tramite de reempadronamiento. <br> El Consejo Directivo de SOSUNC nos solicita que le informemos<br> que el trámite es obligatorio y debe realizarse. <br> No se emitirán órdenes si el trámite no ha sido realizado. <br> <b>El que expenda ordenes, podría ser sancionado</b>.'
,runrecord.idtiposdoc,runrecord.nrodoc,'2019-12-31',2);
INSERT INTO temp_afiliaciones_gestionalertasafiliado (iafechaini,iagrupofamiliar,iatexto,tipodoc,nrodoc,iafechafin,idinfoafiliadoquienmuestra)  
VALUES('2019-07-21',true,'De acuerdo a los registros en sistema, usted no ha realizado el tramite de reempadronamiento. <br> El Consejo Directivo de SOSUNC nos solicita que le informemos<br> que el trámite es obligatorio y debe realizarse. <br> No se emitirán órdenes si el trámite no ha sido realizado. <br> <b>El que expenda ordenes, podría ser sancionado</b>.'
,runrecord.idtiposdoc,runrecord.nrodoc,'2019-12-31',4);
INSERT INTO temp_afiliaciones_gestionalertasafiliado (iafechaini,iagrupofamiliar,iatexto,tipodoc,nrodoc,iafechafin,idinfoafiliadoquienmuestra)  
VALUES('2019-07-21',true,'De acuerdo a los registros en sistema, usted no ha realizado el tramite de reempadronamiento. <br> El Consejo Directivo de SOSUNC nos solicita que le informemos<br> que el trámite es obligatorio y debe realizarse. <br> No se emitirán órdenes si el trámite no ha sido realizado. <br> <b>El que expenda ordenes, podría ser sancionado</b>.'
,runrecord.idtiposdoc,runrecord.nrodoc,'2019-12-31',5);
INSERT INTO temp_afiliaciones_gestionalertasafiliado (iafechaini,iagrupofamiliar,iatexto,tipodoc,nrodoc,iafechafin,idinfoafiliadoquienmuestra)  
VALUES('2019-07-21',true,'De acuerdo a los registros en sistema, usted no ha realizado el tramite de reempadronamiento. <br> El Consejo Directivo de SOSUNC nos solicita que le informemos<br> que el trámite es obligatorio y debe realizarse. <br> No se emitirán órdenes si el trámite no ha sido realizado. <br> <b>El que expenda ordenes, podría ser sancionado</b>.'
,runrecord.idtiposdoc,runrecord.nrodoc,'2019-12-31',6);

SELECT INTO respuesta * FROM afiliaciones_gestionalertasafiliado();

IF respuesta THEN 
	UPDATE w_afiliados_notificados SET idinfoafiliado = currval('infoafiliado_idinfoafiliado_seq'::regclass),idcentroinfoafiliado = centro()
		WHERE nrodoc = runrecord.nrodoc AND idtiposdoc = runrecord.idtiposdoc;
END IF;
	
DELETE FROM temp_afiliaciones_gestionalertasafiliado;

FETCH cursorr INTO runrecord;
END LOOP;
CLOSE cursorr;
RETURN true;
END;$function$
