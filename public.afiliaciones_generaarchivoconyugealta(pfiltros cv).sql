CREATE OR REPLACE FUNCTION public.afiliaciones_generaarchivoconyugealta(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE

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
  vfechageneracion DATE;
  vpadronactivosal TIMESTAMP;
  
   
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
separador = '|';
respuesta = '';
contenido = '';
encabezado = '';
finarchivo = '';
ptipoarchivo = rfiltros.tipoarchivo;
vpadronactivosal = rfiltros.fechafin;
enter = '
';

SELECT INTO vfechageneracion MAX(atfechageneracion) FROM far_archivotrazabilidadtipos NATURAL JOIN far_archivotrazabilidad WHERE atradiscriminante=8  ;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;

IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

INSERT INTO far_archivotrazabilidad(atratipoarchivo,idusuario) 
(SELECT ptipoarchivo,rusuario.idusuario 
);

idarchivo = currval('far_archivotrazabilidad_idarchivostrazabilidad_seq'::regclass);

OPEN cursorarchi FOR SELECT 'DNI'::varchar as tipodocdestitu,p.nrodoc as nrodoctitu,p.tipodoc as tipodoctitu, concat(p.apellido,' ', p.nombres) as titular,'DNI'::varchar as tipodocdes,legajosiu as nrolegajo,p2.nrodoc as nrodocalta,p2.tipodoc as tipodocbenef, concat(p2.apellido,' ', p2.nombres) as beneficiarioalta
                       FROM afilsosunc NATURAL JOIN persona p LEFT JOIN (SELECT legajosiu,nrodoc,tipodoc FROM afilidoc
                                   UNION
                                   SELECT legajosiu,nrodoc,tipodoc FROM afilinodoc
                                   UNION
                                   SELECT legajosiu,nrodoc,tipodoc FROM afiliauto) as legajo USING(nrodoc,tipodoc)
                      JOIN benefsosunc as bb ON (p.nrodoc= bb.nrodoctitu AND p.tipodoc= bb.tipodoctitu)
                      JOIN persona p2 ON(bb.nrodoc= p2.nrodoc AND bb.tipodoc = p2.tipodoc)
                      WHERE p2.barra = 1 AND p2.fechainios >=vfechageneracion and p2.fechainios <= p2.fechafinos;

	FETCH cursorarchi into relem;
	    WHILE  found LOOP
                fila = concat(relem.tipodocdestitu, separador
		      ,relem.nrodoctitu, separador 
		      ,relem.titular,separador
		      ,relem.tipodocdes,separador
                      ,relem.nrolegajo,separador
		      ,relem.nrodocalta,separador
		      ,relem.beneficiarioalta
		      );
		       
		contenido = concat(contenido,fila,enter);
		nombrearchivo = concat('_',rfiltros.tipoarchivo,'_',to_char(vpadronactivosal,'YY'),to_char(vpadronactivosal,'MM'));
		
		INSERT INTO far_archivotrazabilidadafiliado(idarchivostrazabilidad,idcentroarchivostrazabilidad,nrodoc,tipodoc,atalinea)
		VALUES(idarchivo,centro(),relem.nrodoctitu,relem.tipodoctitu,fila);

	    FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;




encabezado = concat('SO',nombrearchivo);
--finarchivo = '';
--contenido = concat(encabezado , enter, contenido);
UPDATE far_archivotrazabilidad SET atracontenidoenvio = contenido, atracontenidorespuesta = encabezado
WHERE idarchivostrazabilidad = idarchivo AND idcentroarchivostrazabilidad = centro();

respuesta = concat(idarchivo,'-' ,centro());


return respuesta;
END;
$function$
