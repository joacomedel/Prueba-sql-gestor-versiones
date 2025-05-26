CREATE OR REPLACE FUNCTION public.alta_modifica_auditoria_medica_pendientes_automaticos(character varying, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

    	nrodocu alias for $1;
	tipodocu alias for $2;
        cconfiguracionespendientes refcursor;
        resultado boolean;
	elem record;
	rconfiguracion record;
	--idtipopres integer;
	rverifica record;
        --vfechavtoconfiguracion date;
        --vfechaingresoconfiguracion date;
        rusuario record;
        rhayconfiguracion record;
	--primero boolean;

BEGIN
	resultado = true;
	--primero = true;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

SELECT INTO rhayconfiguracion   
				ROW_NUMBER () OVER (ORDER BY periodo,alcancecobertura.idcentroalcancecobertura,alcancecobertura.idalcancecobertura) as id
				,CASE WHEN periodo = 'm' THEN date_trunc('month',fecha_desde)::date 
					WHEN periodo = 'a' THEN date_trunc('year',fecha_desde)::date
					ELSE null END as fechaprimeraconf
				,CASE WHEN periodo = 'm' THEN (date_trunc('month',fecha_desde) + INTERVAL '1 MONTH - 1 day' )::date 
					WHEN periodo = 'a' THEN (date_trunc('year',fecha_desde) + INTERVAL '1 year - 1 day' )::date 
					ELSE null END as fechaprimeraconfvto
				,CASE WHEN periodo = 'm' THEN date_trunc('month',fecha_hasta)::date 
					WHEN periodo = 'a' THEN date_trunc('year',fecha_hasta)::date
					ELSE null END as fechaultimaconfig
				,CASE WHEN periodo = 'm' THEN (date_trunc('month',fecha_hasta) + INTERVAL '1 MONTH - 1 day' )::date 
					WHEN periodo = 'a' THEN (date_trunc('year',fecha_hasta) + INTERVAL '1 year - 1 day' )::date 
					ELSE null END as fechaultimaconfigvto
				,current_date as fechaingresoconfiguracion
				,current_date as fechavtoconfiguracion
				,*
				FROM mapea_certdisc_alcancecobertura 
				JOIN  alcancecobertura USING(idalcancecobertura,idcentroalcancecobertura)
				JOIN certificadodiscapacidad USING(idcertdiscapacidad,idcentrocertificadodiscapacidad)
				NATURAL JOIN fichamedica
				WHERE nrodoc = nrodocu AND tipodoc = tipodocu --'05389938'
				AND fecha_desde <= CURRENT_DATE
				AND fecha_hasta >= CURRENT_DATE
				--AND periodo = 'm'
				AND idauditoriatipo=5
            LIMIT 1;

IF FOUND THEN 

IF NOT iftableexists('temp_configuracion') THEN

CREATE TEMP TABLE temp_configuracion AS (SELECT  
				ROW_NUMBER () OVER (ORDER BY periodo,alcancecobertura.idcentroalcancecobertura,alcancecobertura.idalcancecobertura) as id
				,CASE WHEN periodo = 'm' THEN date_trunc('month',fecha_desde)::date 
					WHEN periodo = 'a' THEN date_trunc('year',fecha_desde)::date
					ELSE null END as fechaprimeraconf
				,CASE WHEN periodo = 'm' THEN (date_trunc('month',fecha_desde) + INTERVAL '1 MONTH - 1 day' )::date 
					WHEN periodo = 'a' THEN (date_trunc('year',fecha_desde) + INTERVAL '1 year - 1 day' )::date 
					ELSE null END as fechaprimeraconfvto
				,CASE WHEN periodo = 'm' THEN date_trunc('month',fecha_hasta)::date 
					WHEN periodo = 'a' THEN date_trunc('year',fecha_hasta)::date
					ELSE null END as fechaultimaconfig
				,CASE WHEN periodo = 'm' THEN (date_trunc('month',fecha_hasta) + INTERVAL '1 MONTH - 1 day' )::date 
					WHEN periodo = 'a' THEN (date_trunc('year',fecha_hasta) + INTERVAL '1 year - 1 day' )::date 
					ELSE null END as fechaultimaconfigvto
				,current_date as fechaingresoconfiguracion
				,current_date as fechavtoconfiguracion
				,*
				FROM mapea_certdisc_alcancecobertura 
				JOIN  alcancecobertura USING(idalcancecobertura,idcentroalcancecobertura)
				JOIN certificadodiscapacidad USING(idcertdiscapacidad,idcentrocertificadodiscapacidad)
				NATURAL JOIN fichamedica
				WHERE nrodoc = nrodocu AND tipodoc = tipodocu --'05389938'
				AND fecha_desde <= CURRENT_DATE
				AND fecha_hasta >= CURRENT_DATE
				--AND periodo = 'm'
				AND idauditoriatipo=5);

ELSE 

DELETE FROM temp_configuracion;
INSERT INTO temp_configuracion (SELECT  
				ROW_NUMBER () OVER (ORDER BY periodo,alcancecobertura.idcentroalcancecobertura,alcancecobertura.idalcancecobertura) as id
				,CASE WHEN periodo = 'm' THEN date_trunc('month',fecha_desde)::date 
					WHEN periodo = 'a' THEN date_trunc('year',fecha_desde)::date
					ELSE null END as fechaprimeraconf
				,CASE WHEN periodo = 'm' THEN (date_trunc('month',fecha_desde) + INTERVAL '1 MONTH - 1 day' )::date 
					WHEN periodo = 'a' THEN (date_trunc('year',fecha_desde) + INTERVAL '1 year - 1 day' )::date 
					ELSE null END as fechaprimeraconfvto
				,CASE WHEN periodo = 'm' THEN date_trunc('month',fecha_hasta)::date 
					WHEN periodo = 'a' THEN date_trunc('year',fecha_hasta)::date
					ELSE null END as fechaultimaconfig
				,CASE WHEN periodo = 'm' THEN (date_trunc('month',fecha_hasta) + INTERVAL '1 MONTH - 1 day' )::date 
					WHEN periodo = 'a' THEN (date_trunc('year',fecha_hasta) + INTERVAL '1 year - 1 day' )::date 
					ELSE null END as fechaultimaconfigvto
				,current_date as fechaingresoconfiguracion
				,current_date as fechavtoconfiguracion
				,*
				FROM mapea_certdisc_alcancecobertura 
				JOIN  alcancecobertura USING(idalcancecobertura,idcentroalcancecobertura)
				JOIN certificadodiscapacidad USING(idcertdiscapacidad,idcentrocertificadodiscapacidad)
				NATURAL JOIN fichamedica
				WHERE nrodoc = nrodocu AND tipodoc = tipodocu --'05389938'
				AND fecha_desde <= CURRENT_DATE
				AND fecha_hasta >= CURRENT_DATE
				--AND periodo = 'm'
				AND idauditoriatipo=5);


END IF;


--Recupero las configuraciones 'MENSUALES' y ANUALES que pueden generar pendientes de emisiones. 
OPEN cconfiguracionespendientes FOR SELECT * FROM temp_configuracion ORDER BY id;
FETCH cconfiguracionespendientes into rconfiguracion;
	WHILE  found LOOP
	--RAISE NOTICE ' Verifico (%)',rconfiguracion.fechaprimeraconf;
	--Verifico que la configuracion es Mensual o Anual
	IF not nullvalue(rconfiguracion.fechaprimeraconf)  THEN
		RAISE NOTICE ' Es diferente de null (%)',rconfiguracion.fechaprimeraconf;

		rconfiguracion.fechaingresoconfiguracion = rconfiguracion.fechaprimeraconf;
		rconfiguracion.fechavtoconfiguracion = rconfiguracion.fechaprimeraconfvto;
		RAISE NOTICE ' Verifico (%) a (%) - (%)',rconfiguracion.fechaingresoconfiguracion,rconfiguracion.fechavtoconfiguracion,rconfiguracion.fechaultimaconfigvto;
		
		WHILE rconfiguracion.fechavtoconfiguracion <= rconfiguracion.fechaultimaconfigvto 
			AND  rconfiguracion.fechaingresoconfiguracion <= CURRENT_DATE LOOP
			
                        UPDATE temp_configuracion SET fechaingresoconfiguracion = rconfiguracion.fechaingresoconfiguracion,fechavtoconfiguracion =rconfiguracion.fechavtoconfiguracion  WHERE id = rconfiguracion.id;
			SELECT INTO resultado * FROM alta_modifica_auditoria_medica_pendientes_automaticos_interno(rconfiguracion.id::integer);
		
			rconfiguracion.fechaingresoconfiguracion = CASE WHEN rconfiguracion.periodo = 'm' THEN (date_trunc('month',rconfiguracion.fechaingresoconfiguracion) + INTERVAL '1 MONTH' )::date
									ELSE (date_trunc('year',rconfiguracion.fechaingresoconfiguracion) + INTERVAL '1 year' )::date END;
			rconfiguracion.fechavtoconfiguracion = CASE WHEN rconfiguracion.periodo = 'm' THEN (date_trunc('month',rconfiguracion.fechavtoconfiguracion) + INTERVAL '2 MONTH - 1 day' )::date
								ELSE (date_trunc('year',rconfiguracion.fechavtoconfiguracion) + INTERVAL '2 year - 1 day' )::date END;
			RAISE NOTICE ' Ahora Verifico (%) a (%) - (%)',rconfiguracion.fechaingresoconfiguracion,rconfiguracion.fechavtoconfiguracion,rconfiguracion.fechaultimaconfigvto;
		
		END LOOP;
	END IF;

FETCH cconfiguracionespendientes into rconfiguracion;
END LOOP;
close cconfiguracionespendientes;

END IF;
return resultado;
END;
$function$
