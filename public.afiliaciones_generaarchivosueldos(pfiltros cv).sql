CREATE OR REPLACE FUNCTION public.afiliaciones_generaarchivosueldos(pfiltros character varying)
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
--LEGAJO - APELLIDO Y NOMBRE TITULAR - NRO DOCUMENTO - CUIL -- APELLIDO Y NOMBRE CONYUGE - NRO DOCUMENTO 
--IF ptipoarchivo = 'SUMAS_Informar' THEN


INSERT INTO far_archivotrazabilidad(atratipoarchivo,idusuario) 
(SELECT ptipoarchivo,rusuario.idusuario 
);

idarchivo = currval('far_archivotrazabilidad_idarchivostrazabilidad_seq'::regclass);

OPEN cursorarchi FOR SELECT nrodoc,'DNI'::varchar as tipodocdes,tipodoc,nrolegajo::varchar,nrocuilini,nrocuildni,nrocuilfin,nombres,apellido,nombreconyuge,apellidoconyuge,nrodocconyuge,'DNI'::varchar as tipodocconyuge, conyuge.descrip AS vinculo
			FROM afilsosunc 
			NATURAL JOIN persona 
			NATURAL JOIN (
				SELECT DISTINCT nrodoc,tipodoc,nrolegajo 
				FROM dh21 
				JOIN cargo ON idcargo = nrocargo
				WHERE mesingreso = date_part('month', current_date -30) 
				AND anioingreso = date_part('year', current_date -30) 
                                AND CASE WHEN rfiltros.tipoarchivo = 'SOSUNC_Sueldos' THEN codigoescalafon = 'SOS' ELSE codigoescalafon <> 'SOS' END 
			) as personasultimaliq
			NATURAL JOIN (
			SELECT nombres as nombreconyuge,apellido as apellidoconyuge,nrodoc as nrodocconyuge,tipodoc as tipodocconyuge,bs.nrodoctitu as nrodoc,bs.tipodoctitu as tipodoc, descrip
			FROM benefsosunc  as bs
			NATURAL JOIN persona NATURAL JOIN vinculos
			LEFT JOIN beneficiariosborrados as bb USING(nrodoc,tipodoc)
			WHERE barra = 1 AND fechafinos >=CURRENT_DATE AND estaactivo
			AND nullvalue(bb.nrodoc)
			) as conyuge
			WHERE fechafinos >=CURRENT_DATE;

	FETCH cursorarchi into relem;
	    WHILE  found LOOP
                fila = concat(
                       relem.nrodoc, separador 
		      ,relem.tipodocdes, separador
		      ,relem.nrolegajo,separador
		      ,relem.nrocuilini,separador
		      ,relem.nrocuildni,separador
		      ,relem.nrocuilfin,separador
		      ,relem.nombres,separador
                      ,relem.apellido,separador
		      ,relem.nombreconyuge,separador		     
		      ,relem.apellidoconyuge,separador
		      ,relem.nrodocconyuge,separador
		      ,relem.tipodocconyuge,separador
                      ,relem.vinculo
		      );
		       
		contenido = concat(contenido,fila,enter);
		nombrearchivo = concat('_',rfiltros.tipoarchivo,'_',to_char(vpadronactivosal,'YY'),to_char(vpadronactivosal,'MM'));
		
		INSERT INTO far_archivotrazabilidadafiliado(idarchivostrazabilidad,idcentroarchivostrazabilidad,nrodoc,tipodoc,atalinea)
		VALUES(idarchivo,centro(),relem.nrodoc,relem.tipodoc,fila);

	    FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;

--	END IF;


encabezado = concat('SO',nombrearchivo);
--finarchivo = '';
--contenido = concat(encabezado , enter, contenido);
UPDATE far_archivotrazabilidad SET atracontenidoenvio = contenido, atracontenidorespuesta = encabezado
WHERE idarchivostrazabilidad = idarchivo AND idcentroarchivostrazabilidad = centro();

respuesta = concat(idarchivo,'-' ,centro());


return respuesta;
END;
$function$
