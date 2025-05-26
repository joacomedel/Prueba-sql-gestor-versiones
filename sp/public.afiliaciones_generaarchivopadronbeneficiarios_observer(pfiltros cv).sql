CREATE OR REPLACE FUNCTION public.afiliaciones_generaarchivopadronbeneficiarios_observer(pfiltros character varying)
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
separador = '';
respuesta = '';
contenido = '';
encabezado = '';
finarchivo = '';
vpadronactivosal = rfiltros.fechafin;
ptipoarchivo = rfiltros.tipoarchivo;

enter = concat(chr(13),chr(10));

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

IF ptipoarchivo = 'Observer_Informar' THEN

INSERT INTO far_archivotrazabilidad(atratipoarchivo,idusuario) 
(SELECT ptipoarchivo,rusuario.idusuario 
);

idarchivo = currval('far_archivotrazabilidad_idarchivostrazabilidad_seq'::regclass);

OPEN cursorarchi FOR SELECT 
			CASE WHEN tipodoc =1 THEN 'D' ELSE 'O' END as tipodocumento
                        ,lpad(nrodoc,8,'0') as numerodocumento
                        ,rpad(apellido,50,' ') as apellido
                        ,rpad(nombres,50,' ') as nombres
                        ,to_char(fechanac,'YYYYMMDD') as fechanacimiento
                        ,persona.sexo
                        ,rpad(concat(nrodoc,lpad(persona.barra,3,'0')),20,' ') as numerocredencial
                        ,rpad(concat(nrodoc,lpad(persona.barra,3,'0')),20,' ') as numeroafiliadoobrasocial
                        ,case when (persona.barra > 29 AND persona.barra < 100 ) OR (persona.barra > 129 AND persona.barra < 199 ) THEN 'T' WHEN persona.barra = 1 THEN 'C' ELSE 'H' END as parentesco
                        ,case when nullvalue(barratitular.nrodoctitu) THEN lpad('',1,' ') ELSE CASE WHEN tipodoc =1 THEN 'D' ELSE 'O' END END as tipodocumentotitular
                        ,case when nullvalue(barratitular.nrodoctitu) THEN lpad('',8,'0') ELSE lpad(barratitular.nrodoctitu,8,'0') END as nrodocumentotitular
                        ,rpad('',11,'0') as cuil
                        ,'H' as estado
                        ,rpad('',50,' ') as domiciliocalle
                        ,rpad('',5,'0') as domicilionumero
                        ,rpad('',40,' ') as domicilioobservaciones 
			,rpad('',8,'0') as localidad
			,rpad('',10,' ') as codigopostal
			,rpad('',5,'0') as caracteristica
			,rpad('',20,' ') as telefono
                        ,persona.nrodoc
                        ,persona.tipodoc
                        FROM persona
			LEFT JOIN (SELECT personatitular.barra,nrodoctitu,persona.nrodoc,persona.tipodoc 
				   FROM persona 
				   NATURAL JOIN (SELECT nrodoc,tipodoc,nrodoctitu,tipodoctitu FROM benefsosunc UNION SELECT nrodoc,tipodoc,nrodoctitu,tipodoctitu FROM benefreci ) as t
				   JOIN persona as personatitular ON nrodoctitu = personatitular.nrodoc AND tipodoctitu = personatitular.tipodoc
				   WHERE (persona.barra < 30 OR persona.barra > 100)  
				   
				   ) as barratitular USING(nrodoc,tipodoc) 
			WHERE not nullvalue(persona.barra) AND persona.nrodoc <> '10000000'  AND persona.nrodoc <> '00000001' AND fechafinos >= vpadronactivosal;
	FETCH cursorarchi into relem;

	    WHILE  found LOOP

                fila = concat(
                       relem.tipodocumento, separador 
		      ,relem.numerodocumento, separador
		      ,relem.apellido,separador
		      ,relem.nombres,separador
		      ,relem.fechanacimiento,separador
		      ,relem.sexo,separador
		      ,relem.numerocredencial,separador
		      ,relem.numeroafiliadoobrasocial,separador
		      ,relem.parentesco,separador	
		      ,relem.tipodocumentotitular, separador 
		      ,relem.nrodocumentotitular, separador
		      ,relem.cuil, separador 
		      ,relem.estado, separador
		      ,relem.domiciliocalle,separador
		      ,relem.domicilionumero,separador
		      ,relem.domicilioobservaciones,separador
		      ,relem.localidad,separador
		      ,relem.codigopostal,separador
                      ,relem.caracteristica,separador
		      ,relem.telefono,separador)		     
		      ;
		
		contenido = concat(contenido,fila,enter);

--KR 03-01-20 en correo 23-12-18 RAS pidio nombre de archivo código de prepago + mes + año “570122019”
		nombrearchivo = concat('10550','SOSUNC',to_char(vpadronactivosal,'MM'),to_char(vpadronactivosal,'YYYY'));
		
		INSERT INTO far_archivotrazabilidadafiliado(idarchivostrazabilidad,idcentroarchivostrazabilidad,nrodoc,tipodoc,atalinea)
		VALUES(idarchivo,centro(),relem.nrodoc,relem.tipodoc,fila);

	    FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;

	END IF;

encabezado = concat('SO',nombrearchivo);
--finarchivo = '';
--contenido = concat(encabezado , enter, contenido);
contenido = concat('@' , nombrearchivo, '@', contenido);
UPDATE far_archivotrazabilidad SET atracontenidoenvio = contenido, atracontenidorespuesta = encabezado
WHERE idarchivostrazabilidad = idarchivo AND idcentroarchivostrazabilidad = centro();

respuesta = concat(idarchivo,'-' ,centro());

return respuesta;
END;
$function$
