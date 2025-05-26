CREATE OR REPLACE FUNCTION public.afiliaciones_generaarchivopadronbeneficiarios_solidez(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  ptipoarchivo alias for $1;
  respuesta varchar;
  cursorarchi REFCURSOR;
  contenido varchar;
  separador varchar;
  encabezado varchar;
  nombrearchivo varchar;
  finarchivo varchar;
  enter varchar;
  fila varchar;
  relem RECORD;
  idarchivo BIGINT;
  rusuario RECORD;
  vpadronactivosal TIMESTAMP;
  
  
   
BEGIN
separador = '';
respuesta = '';
contenido = '';
encabezado = '';
finarchivo = '';
vpadronactivosal = now();


enter = '
';


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

IF ptipoarchivo = 'SOLIDEZ_Informar' THEN


INSERT INTO far_archivotrazabilidad(atratipoarchivo,idusuario) 
(SELECT ptipoarchivo,rusuario.idusuario 
);

idarchivo = currval('far_archivotrazabilidad_idarchivostrazabilidad_seq'::regclass);

OPEN cursorarchi FOR SELECT '0380' as nrocontrato
			,1 as tipodoc
			,lpad(nrodoc,8,'0') as nrodoc 
			,rpad(CASE WHEN nullvalue(codpostal) THEN '0000' ELSE codpostal END,5,'0') as codpostal
			,to_char(fechanac,'YYYYMMDD') as fechanac
			,sexo
			,lpad(concat('|',nrodoc,'-',tipodoc),16,'0') as clave
			,to_char(fechainios,'YYYYMMDD') as fechainios
			,rpad(concat(apellido,' ',nombres),40,' ') as apellidonombre
			,rpad(' ',30,' ') as domicilio
			,rpad(' ',20,' ') as telefono
			,rpad(' ',10,' ') as fax
			,rpad(' ',11,' ') as cuitbeneficiario
			,'*' as estatus
			,'30590509643' as cuitcontratante
			,CASE WHEN (persona.barra = 35 OR persona.barra = 34 OR barratitular.barra = 35 OR barratitular.barra = 34) THEN 'G' ELSE 'E' END as condicioniva
			FROM persona
			LEFT JOIN direccion USING(iddireccion,idcentrodireccion)
			LEFT JOIN localidad USING(idlocalidad)
			LEFT JOIN (SELECT personatitular.barra ,persona.nrodoc,persona.tipodoc 
				   FROM persona 
				   NATURAL JOIN benefsosunc
				   JOIN persona as personatitular ON nrodoctitu = personatitular.nrodoc AND tipodoctitu = personatitular.tipodoc
				   WHERE persona.barra < 30 AND persona.tipodoc = 1
				   ) as barratitular USING(nrodoc,tipodoc) 
			WHERE fechafinos >= vpadronactivosal::date AND persona.tipodoc = 1
			AND persona.barra < 100;

	FETCH cursorarchi into relem;
	    WHILE  found LOOP
                fila = concat(
                       relem.nrocontrato, separador 
		      ,relem.tipodoc, separador
		      ,relem.nrodoc,separador
		      ,relem.codpostal,separador
		      ,relem.fechanac,separador
		      ,relem.sexo,separador
		      ,relem.clave,separador
		      ,relem.fechainios,separador
		      ,relem.apellidonombre,separador
		      ,relem.domicilio,separador
		      ,relem.telefono,separador
		      ,relem.fax,separador
		      ,relem.cuitbeneficiario,separador
		      ,relem.estatus,separador
		      ,relem.cuitcontratante,separador
                      ,relem.condicioniva,separador
		      );
		       
		contenido = concat(contenido,fila,enter);
		nombrearchivo = concat(relem.nrocontrato::text,to_char(vpadronactivosal,'YY'),to_char(vpadronactivosal,'MM'));
		
		INSERT INTO far_archivotrazabilidadafiliado(idarchivostrazabilidad,idcentroarchivostrazabilidad,nrodoc,tipodoc,atalinea)
		VALUES(idarchivo,centro(),relem.nrodoc,relem.tipodoc,fila);

	    FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;

	END IF;


encabezado = concat('SO',nombrearchivo);
--finarchivo = '';
--contenido = concat(encabezado , enter, contenido);
UPDATE far_archivotrazabilidad SET atracontenidoenvio = contenido, atracontenidorespuesta = encabezado
WHERE idarchivostrazabilidad = idarchivo AND idcentroarchivostrazabilidad = centro();

respuesta = concat(idarchivo,'-' ,centro());


return respuesta;
END;
$function$
