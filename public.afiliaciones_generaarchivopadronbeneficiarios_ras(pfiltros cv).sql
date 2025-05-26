CREATE OR REPLACE FUNCTION public.afiliaciones_generaarchivopadronbeneficiarios_ras(pfiltros character varying)
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
separador = ';';
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

IF ptipoarchivo = 'RAS_Informar' THEN


INSERT INTO far_archivotrazabilidad(atratipoarchivo,idusuario) 
(SELECT ptipoarchivo,rusuario.idusuario 
);

idarchivo = currval('far_archivotrazabilidad_idarchivostrazabilidad_seq'::regclass);

--KR 02-01-20 en correo 27-12 RAS pidio Eliminar los espacios en blanco a la derecha de los campos apellidos y nombres
OPEN cursorarchi FOR SELECT '570' as codigo
			,lpad(concat(nrodoc,persona.barra),10,'0') as nroafi
                       /* ,rpad(trim(apellido),30,' ') as ape
                        ,rpad(trim(nombres),30,' ') as nom*/
                        ,trim(apellido) as ape
                        ,trim(nombres) as nom
			,lpad(nrodoc,8,'0') as nrodoc 
			,'DNI' as dtipodoc
			,persona.tipodoc as tipodoc
			,persona.sexo
			,rpad('',40,' ') as domicilio
			,rpad('0',4,' ') as cp
			,rpad('',35,' ') as localidad
			,rpad('',30,' ') as departam
			,rpad('',20,' ') as provincia
			,to_char(fechanac,'YYYY-MM-DD') as fenaci
                        ,to_char(fechainios,'YYYY-MM-DD') as ingreso
			,'0' as categoria
--KR 02-01-20 en correo 27-12 RAS pidio El campo IVA registrarlo como V o F
                        ,(CASE WHEN (persona.barra = 35 OR persona.barra = 36 OR barratitular.barra = 35 OR barratitular.barra = 36) THEN 'V' ELSE 'F' END)::varchar as iva 
    --KR 06-01-20 la fecha es la fecha de cierre
                        ,to_char(vpadronactivosal,'YYYY-MM-DD') as carga
                 
--,to_char(date_trunc('month',vpadronactivosal) -'1sec' ::interval,'YYYY-MM-DD') as carga --Ultimo dia del mes anterior
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
			AND persona.barra < 100 AND fechainios<=vpadronactivosal::date;

	FETCH cursorarchi into relem;

	    WHILE  found LOOP

                fila = concat(
                       relem.codigo, separador 
		      ,relem.nroafi, separador
		      ,relem.ape,separador
		      ,relem.nom,separador
		      ,relem.nrodoc,separador
		      ,relem.dtipodoc,separador
		      ,relem.sexo,separador
		      ,relem.domicilio,separador
		      ,relem.cp,separador
		      ,relem.localidad,separador
		      ,relem.departam,separador
		      ,relem.provincia,separador
		      ,relem.fenaci,separador
                      ,relem.ingreso,separador
		      ,relem.categoria,separador)		     
		      ||
                      concat(relem.iva,separador
                     ,relem.carga);
		
		contenido = concat(contenido,fila,enter);

--KR 03-01-20 en correo 23-12-18 RAS pidio nombre de archivo código de prepago + mes + año “570122019”
		nombrearchivo = concat('570',to_char(vpadronactivosal,'MM'),to_char(vpadronactivosal,'YYYY'));
		
		INSERT INTO far_archivotrazabilidadafiliado(idarchivostrazabilidad,idcentroarchivostrazabilidad,nrodoc,tipodoc,atalinea)
		VALUES(idarchivo,centro(),relem.nrodoc,relem.tipodoc,fila);

	    FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;

	END IF;


encabezado = concat('SO',nombrearchivo);
--finarchivo = '';
--contenido = concat(encabezado , enter, contenido);
--KR 13-01-20 Guardo en el contenido el nombre del archivo y luego lo recupero para mandarlo tal cual lo quiere RAS
contenido = concat('@' , nombrearchivo, '@', contenido);
UPDATE far_archivotrazabilidad SET atracontenidoenvio = contenido, atracontenidorespuesta = encabezado
WHERE idarchivostrazabilidad = idarchivo AND idcentroarchivostrazabilidad = centro();

respuesta = concat(idarchivo,'-' ,centro());


return respuesta;
END;
$function$
