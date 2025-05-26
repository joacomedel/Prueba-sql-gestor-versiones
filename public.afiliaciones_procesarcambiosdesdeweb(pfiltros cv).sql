CREATE OR REPLACE FUNCTION public.afiliaciones_procesarcambiosdesdeweb(pfiltros character varying)
 RETURNS text
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

DECLARE
	cprocesarcambios refcursor;
	rfiltros record;
	rusuario RECORD;
	resultado TEXT;
	vprocesados INTEGER;
	vnoprocesados INTEGER;
	rbenefborrado RECORD;
	rdireccion RECORD;
	rweb RECORD;
	marcarprocesada boolean;
        vtieneamuc boolean;
        vtextoauxiliar text;
	
	

BEGIN

--RAISE NOTICE 'Lala (%),(%),(%)',rfiltros.nrodoc,rfiltros.tipodoc,rweb;
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;
--vcambio= false;
EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

vprocesados = 0;
vnoprocesados = 0;
vtextoauxiliar = '';
 OPEN cprocesarcambios FOR  SELECT ad.*,cambio FROM temp_w_procesarcambios as t
				 JOIN w_afiliaciondatos as ad on ((t.nrodoc = ad.nrodoc AND t.tipodoc = ad.idtiposdoc) 
								  OR (t.nrodoc = ad.nrodoctitu)) 
				 --JOIN persona on (persona.nrodoc = ad.nrodoc AND persona.tipodoc = ad.idtiposdoc) 							
				 WHERE nullvalue(adfechaproceso)
				 ORDER BY nrodoctitu;
     FETCH cprocesarcambios into rweb;
     WHILE FOUND LOOP
     IF rweb.cambio = 'SI' OR TRUE THEN  
	marcarprocesada = true;
	UPDATE persona SET nombres = rweb.adnombre,
			--nombres = rweb.adnombre,
			apellido = rweb.adapellido,
			sexo = rweb.adsexo,
			fechanac = rweb.adfechanac,
			estcivil = rweb.idtestadocivil,
			carct = '',
			telefono = concat(rweb.adtelfijo,' ',rweb.adcel),
			email = rweb.ademail
			--nombres = rweb.adnombre

	WHERE nrodoc = rweb.nrodoc AND tipodoc = rweb.idtiposdoc;

	RAISE NOTICE 'Lala (%),(%)',rweb.idosexterna,rweb.adotraos;
	UPDATE afilsosunc SET
			idosexterna = rweb.idosexterna,
			nroosexterna = CASE WHEN trim(rweb.adotraos)='' OR nullvalue(rweb.adotraos) THEN null ELSE rweb.adotraos::bigint END
	WHERE nrodoc = rweb.nrodoc AND tipodoc = rweb.idtiposdoc; 

	UPDATE benefsosunc SET
			idosexterna = rweb.idosexterna,
			nroosexterna = CASE WHEN trim(rweb.adotraos)='' OR nullvalue(rweb.adotraos) THEN null ELSE rweb.adotraos::bigint END
	WHERE nrodoc = rweb.nrodoc AND tipodoc = rweb.idtiposdoc; 
	SELECT INTO rdireccion * FROM persona WHERE nrodoc = rweb.nrodoc AND tipodoc = rweb.idtiposdoc; 

	UPDATE direccion SET
			nro = CASE WHEN trim(rweb.adnumero)='' OR nullvalue(rweb.adnumero) THEN 0 ELSE rweb.adnumero::bigint END ,
			barrio = rweb.adbarrio,
			calle = rweb.adcalle,
			idlocalidad = rweb.idlocalidad,
			piso = rweb.adpiso,
			dpto = rweb.addepartamento,
			idprovincia = rweb.idprovincia
	WHERE iddireccion = rdireccion.iddireccion AND idcentrodireccion = rdireccion.idcentrodireccion;
	SELECT INTO vtieneamuc expendio_tiene_amuc(rweb.nrodoc,rweb.idtiposdoc);
	IF vtieneamuc <> rweb.adamuc  THEN 
                vtextoauxiliar = concat(vtextoauxiliar,' Se informa que ',rweb.adnombre,' ',rweb.adapellido,' tiene amuc? ',CASE WHEN rweb.adamuc THEN 'SI' ELSE 'NO' END,' y el sistema dice que? ',CASE WHEN vtieneamuc THEN 'SI' ELSE 'NO' END,'. Verificar.');
                RAISE NOTICE 'Error hay diferencias con amuc (%,%,%),(%)',rweb.nrodoc,rweb.idtiposdoc,vtieneamuc,rweb.adamuc; 
		marcarprocesada = false;
	END IF;
	IF not nullvalue(rweb.adbaja) THEN
		SELECT INTO rbenefborrado * FROM beneficiariosborrados WHERE nrodoc = rweb.nrodoc AND tipodoc = rweb.idtiposdoc; 
		IF NOT FOUND THEN 
			INSERT INTO beneficiariosborrados(barramutu,nroosexterna,idosexterna,nrodoc,mutual,nrodoctitu,nromututitu,idestado,tipodoc,tipodoctitu,idvin,barratitu)
			(
			SELECT barramutu,nroosexterna,idosexterna,nrodoc,mutual,nrodoctitu,nromututitu,idestado,tipodoc,tipodoctitu,idvin,barratitu
			FROM benefsosunc 
			WHERE nrodoc = rweb.nrodoc AND tipodoc = rweb.idtiposdoc
			);	
		END IF;
                
		UPDATE benefsosunc SET estaactivo = false,idestado=4  WHERE nrodoc = rweb.nrodoc AND tipodoc = rweb.idtiposdoc AND (idestado <> 4 OR estaactivo); 
		UPDATE persona set fechafinos= CURRENT_DATE - 1  WHERE nrodoc = rweb.nrodoc AND tipodoc = rweb.idtiposdoc AND fechafinos >= current_date; 
		
        END IF;
END IF;

IF marcarprocesada THEN
	INSERT INTO w_afiliaciondatos_procesado(idafiliaciondatos,adfechaproceso,adusuarioproceso,adfechacargar)
			VALUES(rweb.idafiliaciondatos,rweb.adfechaproceso,rusuario.idusuario,rweb.adfechacargar);
	UPDATE w_afiliaciondatos SET adfechaproceso = now(), adfechacargar = null WHERE idafiliaciondatos = rweb.idafiliaciondatos;
	vprocesados = vprocesados + 1;
ELSE 
	vnoprocesados = vnoprocesados + 1;
END IF;

	
    
FETCH cprocesarcambios into rweb;
     END LOOP;
     CLOSE cprocesarcambios;

resultado = concat('<span>','Se procesaron correctamente ',vprocesados,'. <br> No se pudieron procesar ',vnoprocesados,'</span><p>'::text,vtextoauxiliar,'</p>');

return resultado;
END;
$function$
