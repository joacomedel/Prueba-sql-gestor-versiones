CREATE OR REPLACE FUNCTION public.afiliaciones_generaarchivopadron_caracteristicas_observer(pfiltros character varying)
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

IF ptipoarchivo = 'Observer_caract_afil' THEN

INSERT INTO far_archivotrazabilidad(atratipoarchivo,idusuario) (SELECT ptipoarchivo,rusuario.idusuario);

idarchivo = currval('far_archivotrazabilidad_idarchivostrazabilidad_seq'::regclass);

OPEN cursorarchi FOR SELECT nrodoc,tipodoc,  rpad(concat(nrodoc,lpad(persona.barra,3,'0')),20,' ') as numeroafiliadoobrasocial
						,CASE WHEN tipodoc =1 THEN 'D' ELSE 'O' END as tipodocumento
                        ,lpad(nrodoc,8,'0') as numerodocumento
						
                         ,rpad(coidobserver,20,' ') as codcaracterisitica
                        ,to_char(pcofechadesde::date,'YYYYMMDD') as fechainivigencia   -- * No es requerido
                        --- ,to_char(fechanac,'YYYYMMDD') as fechafinvigencia  * No es requerido
                        ,'        ' as fechafinvigencia
                     FROM persona
		     NATURAL JOIN persona_caract_observer    ---- tabla que guarda la relacion entre persona y caractaristica
                     NATURAL JOIN caracteristicaobserver
		     LEFT JOIN (SELECT personatitular.barra,nrodoctitu,persona.nrodoc,persona.tipodoc 
				   				FROM persona 
				   				NATURAL JOIN (SELECT nrodoc,tipodoc,nrodoctitu,tipodoctitu FROM benefsosunc UNION SELECT nrodoc,tipodoc,nrodoctitu,tipodoctitu FROM benefreci
			         			)  as t
				   	 			JOIN persona as personatitular ON nrodoctitu = personatitular.nrodoc AND tipodoctitu = personatitular.tipodoc
				   	 			WHERE (persona.barra < 30 OR persona.barra > 100)  
				   
				      ) as barratitular USING(nrodoc,tipodoc) 
			          WHERE not nullvalue(persona.barra) AND nullvalue(pcofechahasta) AND nullvalue(cobaja)
					        AND persona.nrodoc <> '10000000'  AND persona.nrodoc <> '00000001' 
							AND fechafinos >= vpadronactivosal;
	FETCH cursorarchi into relem;

	    WHILE  found LOOP

                fila = concat( relem.numeroafiliadoobrasocial, separador 
		                       ,relem.tipodocumento, separador
		                       ,relem.numerodocumento,separador
		                       ,relem.codcaracterisitica,separador
                                       ,relem.fechainivigencia,separador
                                       ,relem.fechafinvigencia,separador);
		
		contenido = concat(contenido,fila,enter);

        --KR 03-01-20 en correo 23-12-18 RAS pidio nombre de archivo código de prepago + mes + año “570122019”
		nombrearchivo = concat('10550','SOSUNC_CA_',to_char(vpadronactivosal,'MM'),to_char(vpadronactivosal,'YYYY'));
		
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
