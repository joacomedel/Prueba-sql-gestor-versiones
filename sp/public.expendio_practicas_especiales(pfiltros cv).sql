CREATE OR REPLACE FUNCTION public.expendio_practicas_especiales(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Esta funcion se usa para la tranascciones TExpenderPracticasEspeciales, siempre va a crear una tabla llamada
temp_expendio_practicas_especiales que va a contaner los datos que se requieren segun el/los parametros de entrada
*/
DECLARE
	vidusuario INTEGER;
	vidtipoordenoriginal INTEGER;
	vidprestadororiginal INTEGER;
	vidformapagooriginal INTEGER;
	rrecibooriginal RECORD;
        practicasconfig refcursor;
	unaconfig RECORD;
        vhtmltexto VARCHAR;
        vhtmlreglas VARCHAR;
	rparam VARCHAR;
	--alta refcursor; 
	--elem RECORD;
	--anterior RECORD;
	--aux RECORD;
	--rconvenio RECORD;
	resultado boolean;
	--idconvenio bigint;
	--verificar RECORD;
	--deno_anterior bigint;
	--idpracticavalor bigint;
	--errores boolean;
	rpracticas RECORD;
	--rconveniodestino RECORD;
    
        rfiltros RECORD;
BEGIN

--vidusuario = sys_dar_usuarioactual();

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

	IF rfiltros.accion = 'expendio_practicas_especiales_traerplanes' THEN
		CREATE TEMP TABLE temp_expendio_practicas_especiales AS (
			SELECT peodescripcion,peocodigopractica,peoagrupador 
			FROM  practica_emitirorden 
			WHERE nullvalue(peofechaanulacion) AND peocodigopractica ilike '%12.42.19.03%'
			GROUP BY peodescripcion,peocodigopractica,peoagrupador
		);
	END IF;
	
	IF rfiltros.accion = 'expendio_practicas_especiales_traerplanes_orden' THEN
		CREATE TEMP TABLE temp_expendio_practicas_especiales AS (
			SELECT case when nullvalue(planpersona.idplancobertura) then 'No tiene el plan activo - Se dara de alta' else 'Tiene el plan activo' end as tieneplantexto,case when nullvalue(planpersona.idplancobertura) then false else true end as tieneplan,peocantidad,peocantidademite,idpracticaemitirorden,peocodigopractica,peoagrupador,peocodigopracticaemite,peoidplancoberturaemite,peoidasocconvemite,peoidtipoordenemite,peofechaconfiguracion,peoidplancobertura,peodescripcion
			,peoidasocconv,pdescripcion,nrocuentac,planoriginal.nombreimprimir as descplanoriginal,asoc_original.acdecripcion as decasoc_original,planemite.nombreimprimir as descplanemite,asoc_emite.acdecripcion as descasoc_emite,'<html>'::varchar as textohtml,'stilos'::varchar as textocss 
			FROM  practica_emitirorden 
			JOIN practica ON peocodigopracticaemite = concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica)
                         LEFT JOIN  plancobpersona as planpersona  ON peoidplancobertura = planpersona.idplancobertura AND (nullvalue(pcpfechafin) OR pcpfechafin >= current_date) AND nrodoc = rfiltros.nrodoc
			LEFT JOIN  plancobertura as planoriginal  ON peoidplancobertura = planoriginal.idplancobertura
			LEFT JOIN  (SELECT acdecripcion,idasocconv  FROM asocconvenio WHERE acactivo GROUP BY acdecripcion,idasocconv) as asoc_original  ON peoidasocconv = asoc_original.idasocconv
			LEFT JOIN  plancobertura as planemite  ON peoidplancoberturaemite  = planemite.idplancobertura
			LEFT JOIN  (SELECT acdecripcion,idasocconv  FROM asocconvenio WHERE acactivo GROUP BY acdecripcion,idasocconv) as asoc_emite  ON peoidasocconvemite = asoc_emite.idasocconv
			WHERE nullvalue(peofechaanulacion)
				AND peoagrupador = rfiltros.peoagrupador
		);

             OPEN practicasconfig FOR  SELECT * FROM temp_expendio_practicas_especiales;
             FETCH practicasconfig INTO unaconfig;
               vhtmltexto = '<html>';

 
               vhtmltexto = concat(vhtmltexto,'<h1>Link al Tutorial:</h1>');
               vhtmltexto = concat(vhtmltexto,'<a href="https://docs.google.com/document/d/1EXy5l86jK46hT7uDtOCSQCtbq_Z8HlI3sUo24XQCoKI/edit" >https://docs.google.com/document/d/1EXy5l86jK46hT7uDtOCSQCtbq_Z8HlI3sUo24XQCoKI/edit</a>');
               vhtmltexto = concat(vhtmltexto,'<h1>Link al Curso:</h1>');
               vhtmltexto = concat(vhtmltexto,'<a href="https://forms.gle/Z17j4DyHxq5aXRMz8" >https://forms.gle/Z17j4DyHxq5aXRMz8</a>');
               vhtmltexto = concat(vhtmltexto,'<h1>Descripcion del Plan:</h1>');
               vhtmltexto = concat(vhtmltexto,'<p>',unaconfig.peodescripcion,'</p>');
                vhtmltexto = concat(vhtmltexto,'<h2>',unaconfig.tieneplantexto,'</h2>');
               vhtmltexto = concat(vhtmltexto,'<h2>Emisión Orden 1:</h2>');
               vhtmltexto = concat(vhtmltexto,'<p>',unaconfig.peocodigopractica,' usando el plan',unaconfig.descplanoriginal,' y la asociacion ',unaconfig.decasoc_original,' </p>');
                vhtmltexto = concat(vhtmltexto,'<h2>Emisión Orden 2:</h2>'); 
            WHILE  found LOOP
               
              
               vhtmltexto = concat(vhtmltexto,'<p>',unaconfig.peocodigopracticaemite,' ',unaconfig.pdescripcion,' usando el plan ',case when nullvalue(unaconfig.descplanemite) then unaconfig.descplanoriginal else unaconfig.descplanemite end,' y la asociacion ',case when nullvalue(unaconfig.descasoc_emite) then unaconfig.decasoc_original else unaconfig.descasoc_emite end,' </p>');
               
             FETCH practicasconfig INTO unaconfig;
             END LOOP;
             CLOSE practicasconfig;
              vhtmlreglas = concat('body {color:#000; font-family:times; margin: 4px; }');
              vhtmlreglas = concat(vhtmlreglas,'h1 {color: blue;}');
              vhtmlreglas = concat(vhtmlreglas,'h2 {color: #ff0000;}');
              vhtmlreglas = concat(vhtmlreglas,'pre {font : 10px monaco; color : black; background-color : #fafafa; }');
		    
             vhtmltexto =  concat(vhtmltexto,'</body></html> ');  
             UPDATE temp_expendio_practicas_especiales set textohtml = vhtmltexto , textocss = vhtmlreglas ; 

	END IF;
	
	IF rfiltros.accion = 'expendio_practicas_especiales_emitir_ordenes' THEN
                        IF not rfiltros.tieneplan THEN
                           PERFORM ingresarpersonaplan(rfiltros.nrodoc,rfiltros.tipodoc,rfiltros.peoidplancobertura,current_date, current_date + 10::integer);
                        END IF;

			vidtipoordenoriginal = 2; --Por defecto se emiten ordenes valorizadas
			vidprestadororiginal = 7841; --Por defecto se emite con el restador sello ilegible
			vidformapagooriginal = 2; --Por defecto emito con forma de pago Caja... incialmente esto era para planes con cobertura al 100
			--MaLaPi 29-06-2022 Se asume que la orden original siempre va a tener una sola practica.
			CREATE TEMP TABLE temporden(nrodoc varchar(8),tipodoc int  NOT NULL,numorden bigint , ctroorden integer, centro int4 NOT NULL,recibo boolean,tipo int8,amuc float ,afiliado float ,sosunc float,enctacte boolean,formapago varchar,idprestador BIGINT,ordenreemitida INTEGER,centroreemitida INTEGER,nromatricula INTEGER,cantordenes INTEGER, idasocconv BIGINT,nroreintegro BIGINT, anio INTEGER,autogestion BOOLEAN DEFAULT false,idcentroreintegro INTEGER ) WITHOUT OIDS;
			--Cargo la tabla tempitems para la practica que se requiere emitir, esta verifica el consumo y determina si requiere o no auditoria
			rparam = concat('{ idplancoberturas=',rfiltros.peoidplancobertura,',idasocconv=',rfiltros.peoidasocconv,',cantidad=',rfiltros.peocantidad,' ,nrodoc=',rfiltros.nrodoc,' ,codigopractica=',rfiltros.peocodigopractica,' }');
			PERFORM generar_orden_consumoafiliado_cargaritem(rparam);
			INSERT INTO temporden(nrodoc,tipodoc,numorden,ctroorden,centro,tipo,amuc,afiliado,sosunc,enctacte,idprestador,ordenreemitida,centroreemitida,nromatricula,cantordenes,idasocconv,nroreintegro,anio,idcentroreintegro) 
			(SELECT rfiltros.nrodoc,rfiltros.tipodoc,null,null,centro(),vidtipoordenoriginal,sum(amuc),sum(afiliado),sum(sosunc),false,vidprestadororiginal,null,null,null,1,rfiltros.peoidasocconv,null,null,null
				FROM tempitems 
			);
	  	 	SELECT INTO rrecibooriginal * FROM expendio_orden();
			IF FOUND THEN
               --KR 06-05-19 Guardo el estado de la orden en la tabla cambioestadoorden 
                PERFORM expendio_cambiarestadoorden (rrecibooriginal.nroorden, rrecibooriginal.centro, 1);
				--MaLaPi 29-06-2022 Por el momento las ordenes de planes no se van a auditar
				--PERFORM w_consumoafiliado_generaauditoria(concat('{"nroorden":',t.nroorden,',', '"centro":',t.centro,',', '"nrodoc":','"',vnrodocumento,'"',',', '"tipodoc":',vidtipodocumento,'}')::jsonb) 
               --FROM ( SELECT nroorden,centro FROM ttordenesgeneradas   as t;
                --DELETE FROM ttordenesgeneradas;
				PERFORM expendio_orden_vinculadas_configuradas();
			END IF;
			CREATE TEMP TABLE temp_expendio_practicas_especiales AS (
					SELECT *,'<html>'::varchar as textohtml,'stilos'::varchar as textocss 
                                        FROM ordenrecibo_vinculada
					WHERE  orvidreciboorigen = rrecibooriginal.idrecibo
							AND orvcentroorigen = rrecibooriginal.centro
			);

          OPEN practicasconfig FOR  SELECT * FROM temp_expendio_practicas_especiales;
             FETCH practicasconfig INTO unaconfig;
               vhtmltexto = '<html>';
               vhtmltexto = concat(vhtmltexto,'<h2>Datos de la Orden 1:</h2>');
               vhtmltexto = concat(vhtmltexto,'<p> Nro.Orden ',unaconfig.orvnroordenorigen,'-',unaconfig.orvcentroorigen,' Nro.Recibo ',unaconfig.orvidreciboorigen,'-',unaconfig.orvcentroorigen,' </p>');
               vhtmltexto = concat(vhtmltexto,'<h2>Datos de la Orden 2:</h2>'); 
            WHILE  found LOOP
               
              vhtmltexto = concat(vhtmltexto,'<p> Nro.Orden ',unaconfig.orvnroordenvinculado,'-',unaconfig.orvcentrovinculado,' Nro.Recibo ',unaconfig.orvidrecibovinculado,'-',unaconfig.orvcentrovinculado,' </p>');
            FETCH practicasconfig INTO unaconfig;
            END LOOP;
            CLOSE practicasconfig;
              vhtmlreglas = concat('body {color:#000; font-family:times; margin: 4px; }');
              vhtmlreglas = concat(vhtmlreglas,'h1 {color: blue;}');
              vhtmlreglas = concat(vhtmlreglas,'h2 {color: #ff0000;}');
              vhtmlreglas = concat(vhtmlreglas,'pre {font : 10px monaco; color : black; background-color : #fafafa; }');
		    
             vhtmltexto =  concat(vhtmltexto,'</body></html> ');  
             UPDATE temp_expendio_practicas_especiales set textohtml = vhtmltexto , textocss = vhtmlreglas ; 

             

	END IF;
	

resultado = 'true';
RETURN resultado;
END;
$function$
