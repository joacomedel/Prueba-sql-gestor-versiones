CREATE OR REPLACE FUNCTION public.alta_modifica_ficha_medica_orden_expendio(pnroorden bigint, pcentro integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  entro BOOLEAN;
  cursorficha refcursor;
  elem RECORD;
  raux record;
  rusuario RECORD;
  --rborrar record;
  rverifica RECORD;
  rrestoinfo RECORD;
 
 

BEGIN

respuesta = true;


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

open cursorficha FOR select nrodoc,tipodoc,nroorden,centro,fechaemision,CASE WHEN orden.tipo = 3 THEN 10 
                           WHEN orden.tipo = 37 THEN 4
                           ELSE 13 END as idfichamedicainfotipos,48 as idfichamedicatratamientotipo,0 as idfichamedica,0 as idcentrofichamedica
			,concat('#',' <',nroorden,'|',centro,'>',' Fecha Emision: ',to_char(fechaemision,'DD-MM-YYYY'),CASE WHEN anulado THEN ' || Orden Anulada || ' ELSE '' END) as info 
			from consumo 
			natural join orden
			where --nrodoc = '07657386' AND 
                                (nroorden = pnroorden OR nullvalue(pnroorden) ) 
				AND ( centro = pcentro OR nullvalue(pcentro) )
			ORDER BY fechaemision 
			--LIMIT 3
			;
FETCH cursorficha INTO elem;
WHILE FOUND LOOP
entro = false;
IF iftableexistsparasp('tempfichamedicainfo') THEN 
        DELETE FROM tempfichamedicainfo;
ELSE 
	CREATE TEMP TABLE tempfichamedicainfo ( idfichamedica INTEGER,fmtfechainicio DATE, idcentrofichamedica INTEGER, idcentrofichamedicainfo INTEGER, idfichamedicainfo INTEGER,fmifecha DATE, fmimfechafin DATE, fmiauditor INTEGER, usuariologueado INTEGER, fmidescripcion character varying, nrodoc VARCHAR, tipodoc INTEGER, fmfechacreacion DATE, fmdescripcion  character varying,idauditoriatipo INTEGER, idcentrofichamedicatratamiento INTEGER, idfichamedicatratamiento INTEGER,idfichamedicatratamientotipo INTEGER,idfichamedicainfotipos INTEGER,eliminar BOOLEAN,idfichamedicainfomedicamento BIGINT,idcentrofichamedicainfomedicamento integer,idplancoberturas BIGINT, idarticulo BIGINT, idcentroarticulo INTEGER, idmonodroga INTEGER, fmimcobertura float, infomedicamentos BOOLEAN  ) WITHOUT OIDS;

END IF;


--Busco su Id de Historia Clinica
			SELECT INTO raux *  FROM fichamedica WHERE  nrodoc= elem.nrodoc AND tipodoc=elem.tipodoc AND idauditoriatipo = 5;
			    IF NOT FOUND THEN
				       INSERT INTO fichamedica(tipodoc,nrodoc,fmdescripcion,idauditoriatipo) 
				       VALUES(elem.tipodoc,elem.nrodoc,'Generada Automaticamente desde SP alta_modifica_ficha_medica_internacion',5);
				       elem.idfichamedica = currval('public.fichamedica_idfichamedica_seq');
				       elem.idcentrofichamedica = centro();
			    ELSE 
				       elem.idfichamedica = raux.idfichamedica;
				       elem.idcentrofichamedica = raux.idcentrofichamedica;
			    
			    END IF;

	--Verifico que tipo de Orden es
			SELECT INTO rrestoinfo concat(elem.info, ' Fecha Internación ',to_char(fechainternacion,'DD-MM-YYYY'),' Cant.Dias: ',cantdias,' Tipo: ',descripcion,' Diagnostico: ',	diagnostico,' Lugar: ',lugarinternacion,'#') as info
                        FROM ordinternacion 
			join tiposinternacion ON tiposinternacion.idtipo	= tipointernacion
			where  nroorden=elem.nroorden
				AND centro=elem.centro; 
			IF FOUND THEN  -- Se trata de una internacion
				elem.info = rrestoinfo.info;
                                entro = true;
			END IF;

			SELECT INTO rrestoinfo 
			descripcion,text_concatenar('* ' || concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica,' (Cant.',cantidad,') -',pdescripcion)) as info
                        FROM ordvalorizada
                        NATURAL JOIN itemvalorizada
                        NATURAL JOIN item
                        NATURAL JOIN practica
                        JOIN plancobertura ON idplancovertura =  idplancobertura
			where  nroorden=elem.nroorden
				AND centro=elem.centro
                         GROUP BY plancobertura.descripcion,nroorden,centro; 
			IF FOUND THEN  -- Se trata de una orden valorizada
				elem.info = concat(elem.info,' Plan: ',rrestoinfo.descripcion,' Practicas: ',rrestoinfo.info,'#');
				entro = true;
			END IF;

			SELECT INTO rrestoinfo 
			descripcion,fechauso,gratuito,text_concatenar('* ' || concat('Troquel:',mtroquel,' Cod.Barra:',mcodbarra,'-',mnombre,' Cob.',coberturaefectiva,'%')) as info
                        FROM recetario 
			NATURAL JOIN recetarioitem
			NATURAL JOIN medicamento
			JOIN plancobertura ON idplancovertura = idplancobertura
			where  nrorecetario=elem.nroorden
				AND centro=elem.centro
                         GROUP BY descripcion,gratuito,fechauso,nrorecetario,centro; 
			IF FOUND THEN  -- Se trata de un recetario auditado
				elem.info = concat(elem.info,CASE WHEN rrestoinfo.gratuito THEN ' Gratuito ' ELSE '' END,' Plan: ',rrestoinfo.descripcion,' Fecha.Uso:',to_char(rrestoinfo.fechauso,'DD-MM-YYYY')	,' Medicamentos: ',rrestoinfo.info,'#');
				entro = true;
			END IF;


	IF entro THEN --Se trata de una orden que requiere guardar info en auditoria
	
-- Verifico si ya existe una auditoria
	SELECT INTO rverifica split_part(split_part(split_part(fmidescripcion,'<',2),'>',1),'|',1) as nroorden,split_part(split_part(split_part(fmidescripcion,'<',2),'>',1),'|',2) as centro
	,fichamedicainfo.*   
	FROM fichamedica  
	natural join fichamedicatratamiento  
	NATURAL JOIN fichamedicatratamientotipo 
	natural join fichamedicainfo  
	NATURAL JOIN persona   
	NATURAL JOIN auditoriatipo
	JOIN orden ON split_part(split_part(split_part(fmidescripcion,'<',2),'>',1),'|',1) = nroorden AND split_part(split_part(split_part(fmidescripcion,'<',2),'>',1),'|',2) = centro
	JOIN consumo USING(nroorden,centro)
	WHERE true --AND idfichamedicainfotipos=10  
	     AND fichamedica.nrodoc=elem.nrodoc 
	     AND fichamedica.tipodoc=elem.tipodoc
	     AND orden.nroorden=elem.nroorden
	     AND orden.centro=elem.centro 
	ORDER BY fmifecha DESC; 
	IF NOT FOUND THEN 

		INSERT INTO tempfichamedicainfo(fmifecha,idfichamedica, idcentrofichamedica,fmiauditor,fmidescripcion,nrodoc,tipodoc,idauditoriatipo,idfichamedicatratamientotipo,idfichamedicainfotipos) 
		VALUES(elem.fechaemision,elem.idfichamedica,elem.idcentrofichamedica,rusuario.idusuario,elem.info,elem.nrodoc,elem.tipodoc,5,elem.idfichamedicatratamientotipo,elem.idfichamedicainfotipos);
	
	ELSE --Existe la auditoria
		INSERT INTO tempfichamedicainfo(idfichamedicatratamiento,idcentrofichamedicatratamiento,idfichamedicainfo,idcentrofichamedicainfo,fmifecha,idfichamedica, idcentrofichamedica,fmiauditor,fmidescripcion,nrodoc,tipodoc,idauditoriatipo,idfichamedicatratamientotipo,idfichamedicainfotipos) 
		VALUES(rverifica.idfichamedicatratamiento,rverifica.idcentrofichamedicatratamiento,rverifica.idfichamedicainfo,rverifica.idcentrofichamedicainfo,elem.fechaemision,elem.idfichamedica,elem.idcentrofichamedica,rusuario.idusuario,elem.info,elem.nrodoc,elem.tipodoc,5,elem.idfichamedicatratamientotipo,elem.idfichamedicainfotipos);
		
	END IF;
		SELECT INTO respuesta * FROM alta_modifica_ficha_medica_();
	END IF;

FETCH cursorficha INTO elem;
END LOOP;
CLOSE cursorficha;


return respuesta;
END;
$function$
