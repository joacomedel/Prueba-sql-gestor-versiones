CREATE OR REPLACE FUNCTION public.afiliaciones_generaarchivopadronbeneficiarios_sumas__(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
  rfiltros RECORD;
  relem RECORD;
  
--CURSORES
  cursorarchi REFCURSOR;
 

--VARIABLES
  ptipoarchivo VARCHAR; 
  respuesta varchar;
  contenido varchar;
  separador varchar;
  encabezado varchar;
  nombrearchivo varchar;
  finarchivo varchar;
  enter varchar;
  fila varchar;
  idarchivo BIGINT;
  rusuario RECORD;
  vpadronactivosal TIMESTAMP;
  
  
   
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
separador = '|';
respuesta = '';
contenido = '';
encabezado = '';
finarchivo = '';
vpadronactivosal = rfiltros.fechafin;
ptipoarchivo = rfiltros.tipoarchivo;

enter = '
';


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

IF ptipoarchivo = 'SUMAS_Informar' THEN


INSERT INTO far_archivotrazabilidad(atratipoarchivo,idusuario) 
(SELECT ptipoarchivo,rusuario.idusuario 
);

idarchivo = currval('far_archivotrazabilidad_idarchivostrazabilidad_seq'::regclass);

OPEN cursorarchi FOR SELECT CONCAT(nrodoc,persona.barra) as nroafiliado
                        ,nombres
                        ,apellido
			,1 as tipodoc
			,lpad(nrodoc,8,'0') as nrodoc 
			,persona.sexo
                        ,to_char(fechanac,'YYYYMMDD') as fechanac
                        ,to_char(fechainios,'YYYYMMDD') as fechainios
                        ,CASE WHEN (persona.barra = 35 OR persona.barra = 36 OR barratitular.barra = 35 OR barratitular.barra = 36) THEN 'J' ELSE 'O' END as condicionafiliado
                        ,rpad(CASE WHEN nullvalue(codpostal) THEN '0000' ELSE codpostal END,4,'0')::numeric as codpostal
			
			
			FROM persona
			LEFT JOIN direccion USING(iddireccion,idcentrodireccion)
			LEFT JOIN localidad USING(idlocalidad)
			LEFT JOIN (SELECT personatitular.barra ,persona.nrodoc,persona.tipodoc 
				   FROM persona 
				   NATURAL JOIN benefsosunc
				   JOIN persona as personatitular ON nrodoctitu = personatitular.nrodoc AND tipodoctitu = personatitular.tipodoc
				   WHERE persona.barra < 30 AND persona.tipodoc = 1
				   ) as barratitular USING(nrodoc,tipodoc) 
			WHERE (CASE WHEN (persona.barra = 35 OR persona.barra = 36 OR barratitular.barra = 35 OR barratitular.barra = 36)  THEN fechafinos+90  ELSE fechafinos   END) >= vpadronactivosal::date AND persona.tipodoc = 1
                        --KR 05-10-20 SACO al afiliado de prueba 
                        AND persona.nrodoc <> '10000000'  AND persona.nrodoc <> '00000001'
			AND persona.barra < 100;

	FETCH cursorarchi into relem;
	    WHILE  found LOOP
                fila = concat(
                       relem.nroafiliado, separador 
		      ,relem.nombres, separador
		      ,relem.apellido,separador
		      ,relem.tipodoc,separador
		      ,relem.nrodoc,separador
		      ,relem.sexo,separador
		      ,relem.fechanac,separador
                      ,relem.condicionafiliado,separador
		      ,relem.fechainios,separador		     
		      ,relem.codpostal
		      );
		       
		contenido = concat(contenido,fila,enter);
		nombrearchivo = concat('_PadronSUMAS',to_char(vpadronactivosal,'YY'),to_char(vpadronactivosal,'MM'));
		
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
