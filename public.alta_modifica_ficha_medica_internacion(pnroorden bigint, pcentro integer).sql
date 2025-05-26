CREATE OR REPLACE FUNCTION public.alta_modifica_ficha_medica_internacion(pnroorden bigint, pcentro integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta BOOLEAN;
  cursorficha refcursor;
  elem RECORD;
  raux record;
  rusuario RECORD;
  --rborrar record;
  rverifica RECORD;
 
 

BEGIN

respuesta = true;


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

open cursorficha FOR select nrodoc,tipodoc,nroorden,centro,fechaemision,10 as idfichamedicainfotipos,50 as idfichamedicatratamientotipo,0 as idfichamedica,0 as idcentrofichamedica
			,concat('#',' <',nroorden,'|',centro,'>',' Fecha Emision: ',to_char(fechaemision,'DD-MM-YYYY'),' Fecha Internación',to_char(fechainternacion,'DD-MM-YYYY'),' Cant.Dias: ',cantdias,' Tipo: ',descripcion,' Diagnostico: ',	diagnostico,' Lugar: ',lugarinternacion,CASE WHEN anulado THEN ' || Orden Anulada ||' ELSE '' END,'#') as info 
			from consumo 
			natural join orden
			natural join ordinternacion
			join tiposinternacion ON tiposinternacion.idtipo	= tipointernacion
			where (nroorden = pnroorden OR nullvalue(pnroorden) ) 
				AND ( centro = pcentro OR nullvalue(pcentro) )
			ORDER BY fechaemision 
			--LIMIT 3
			;
FETCH cursorficha INTO elem;
WHILE FOUND LOOP

IF iftableexistsparasp('tempfichamedicainfo') THEN 
        DELETE FROM tempfichamedicainfo;
ELSE 
	CREATE TEMP TABLE tempfichamedicainfo ( idfichamedica INTEGER,fmtfechainicio DATE, idcentrofichamedica INTEGER, idcentrofichamedicainfo INTEGER, idfichamedicainfo INTEGER,fmifecha DATE, fmimfechafin DATE, fmiauditor INTEGER, usuariologueado INTEGER, fmidescripcion character varying, nrodoc VARCHAR, tipodoc INTEGER, fmfechacreacion DATE, fmdescripcion  character varying,idauditoriatipo INTEGER, idcentrofichamedicatratamiento INTEGER, idfichamedicatratamiento INTEGER,idfichamedicatratamientotipo INTEGER,idfichamedicainfotipos INTEGER,eliminar BOOLEAN,idfichamedicainfomedicamento BIGINT,idcentrofichamedicainfomedicamento integer,idplancoberturas BIGINT, idarticulo BIGINT, idcentroarticulo INTEGER, idmonodroga INTEGER, fmimcobertura float, infomedicamentos BOOLEAN  ) WITHOUT OIDS;

END IF;

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
	WHERE true AND idfichamedicainfotipos=10  
	     AND fichamedica.nrodoc=elem.nrodoc 
	     AND fichamedica.tipodoc=elem.tipodoc
	     AND orden.nroorden=elem.nroorden
	     AND orden.centro=elem.centro 
	ORDER BY fmifecha DESC; 
IF NOT FOUND THEN 

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


	INSERT INTO tempfichamedicainfo(fmifecha,idfichamedica, idcentrofichamedica,fmiauditor,fmidescripcion,nrodoc,tipodoc,idauditoriatipo,idfichamedicatratamientotipo,idfichamedicainfotipos) 
	VALUES(elem.fechaemision,elem.idfichamedica,elem.idcentrofichamedica,rusuario.idusuario,elem.info,elem.nrodoc,elem.tipodoc,5,elem.idfichamedicatratamientotipo,elem.idfichamedicainfotipos);


	SELECT INTO respuesta * FROM alta_modifica_ficha_medica_();

END IF;

FETCH cursorficha INTO elem;
END LOOP;
CLOSE cursorficha;


return respuesta;
END;
$function$
