CREATE OR REPLACE FUNCTION public.far_guardararchivorespuestatrazabilidad()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  respuesta varchar;
  cursorarchi REFCURSOR;
  contenido varchar;
  separador varchar;
  enter varchar;
  fila varchar;
  relem RECORD;
  idarchivo BIGINT;
  rusuario RECORD;
  rverifica RECORD;
  rprecargarpedidocompcatalogo RECORD;
  rprestador RECORD;
  rcompcatalogo far_precargarpedidocompcatalogo%ROWTYPE;
  rarticulo far_articulo%ROWTYPE; 
   
BEGIN
separador = ',';
respuesta = '';
contenido = '';
enter = '
';


SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

SELECT * INTO  rverifica FROM temporal_archivotrazabilidad as t 
			JOIN far_archivotrazabilidad as fat
			ON split_part(t.nombrearchivo, '.rep',1)::bigint = idarchivostrazabilidad
			AND idcentroarchivostrazabilidad = centro()
			AND atratipoarchivo = t.tipoarchivo
WHERE nullvalue(fat.atracontenidorespuesta);

IF NOT FOUND THEN 

respuesta = concat('El archivo no Existe o ya se proceso.','-' ,rverifica.nombrearchivo);

ELSE 

IF rverifica.tipoarchivo = '#VF_A_RECIBIR' THEN
	OPEN cursorarchi FOR SELECT CASE WHEN nullvalue(nrofactura) THEN nroremito ELSE nrofactura END as nrofactura
	,CASE WHEN nullvalue(nrofactura) THEN 'REM' ELSE 'FAC' END as tipofactura
        ,substr(left(atcodigotrazabilidad,position('' in atcodigotrazabilidad)-1), 19 ) as atserie
	,* FROM temporal_archivotrazabilidad;
	FETCH cursorarchi into relem;
	    WHILE  found LOOP
	    UPDATE far_archivotrazabilidad SET atracontenidorespuesta = concat(atracontenidorespuesta,enter,relem.linea) 
			WHERE 	idarchivostrazabilidad = rverifica.idarchivostrazabilidad 
			AND idcentroarchivostrazabilidad = rverifica.idcentroarchivostrazabilidad;
			
		SELECT * INTO rprestador FROM prestador WHERE gln = relem.gln;
		IF NOT FOUND THEN 
			rprestador.idprestador = null;
		END IF;

		SELECT * INTO rcompcatalogo FROM far_precargarpedidocompcatalogo 
		         WHERE idprestador =rprestador.idprestador AND  trim(numfactura) = trim(substring(relem.nrofactura from 2))
                               AND letra = substring(relem.nrofactura from 1 for 1)
                               AND tipofactura = relem.tipofactura;
		IF NOT FOUND THEN 
			--SELECT 	substring(relem.nrofactura from 1 for 1) as letra,substring(relem.nrofactura from 2) as numfactura,1 as idtipocomprobante, as fechaemision,'FAC' as tipofactura INTO rcompcatalogo;
			INSERT INTO far_precargarpedidocompcatalogo(idprecargarpedidocompcatalogo,idcentroprecargarpedidocompcatalogo,
			numfactura,idtipocomprobante,fechaemision,letra,tipofactura,idprestador,idusuario
			,idarchivostrazabilidad
			,idcentroarchivostrazabilidad)
			VALUES(nextval('far_precargarpedidocompcatalo_idprecargarpedidocompcatalogo_seq'::regclass),centro(),
			substring(relem.nrofactura from 2),1,null,substring(relem.nrofactura from 1 for 1),relem.tipofactura,rprestador.idprestador
			,rusuario.idusuario
			,rverifica.idarchivostrazabilidad,rverifica.idcentroarchivostrazabilidad);

			rcompcatalogo.idprecargarpedidocompcatalogo=currval('far_precargarpedidocompcatalo_idprecargarpedidocompcatalogo_seq'::regclass);
			rcompcatalogo.idcentroprecargarpedidocompcatalogo = centro();

		END IF;
		
		SELECT * INTO rarticulo FROM far_articulo WHERE acodigobarra = substring(relem.atcodigotrazabilidad from 3 for 13);
		
		INSERT INTO far_articulotrazabilidad(idarticulotraza,idcentroarticulotraza,
			idprecargarpedidocompcatalogo,idcentroprecargarpedidocompcatalogo, 
			--idarticulocomprobantecompra,idcentroarticulocomprobantecompra, --Eliminamos esta tabla. Quedan en nulos hasta que los seleccione
			idprecargarpedido,idcentroprecargapedido, --Quedan en nulos, hasta que los seleccione
			idarticulo,idcentroarticulo,
			atcodigotrazabilidad,atcodigobarragtin,atlote,atvencimiento,atserie) 
		VALUES(nextval('far_articulotrazabilidad_idarticulotraza_seq'::regclass),centro(),
		rcompcatalogo.idprecargarpedidocompcatalogo,rcompcatalogo.idcentroprecargarpedidocompcatalogo,
		null,null,
		null,null,
		rarticulo.idarticulo,rarticulo.idcentroarticulo,
		relem.atcodigotrazabilidad,relem.atcodigobarragtin,relem.atlote,to_date(relem.atvencimiento,'DD/MM/YYYY'),relem.atserie);

		INSERT INTO far_articulotrazabilidadestado(idarticulotrazabilidadestadotipos,
		   idarticulotraza,idcentroarticulotraza,atedescripcion)
		   VALUES(1,currval('far_articulotrazabilidad_idarticulotraza_seq'::regclass),centro(),concat('Al Procesar el archivo ',relem.nombrearchivo));

		INSERT INTO far_archivotrazabilidadarticulo(idarchivostrazabilidad,idcentroarchivostrazabilidad
		,idarticulotraza,idcentroarticulotraza
		,atalinea)
		VALUES(rverifica.idarchivostrazabilidad,rverifica.idcentroarchivostrazabilidad
		,currval('far_articulotrazabilidad_idarticulotraza_seq'::regclass),centro(),relem.linea);

	    FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;

	respuesta = concat('El archivo Se proceso correctamente.','-' ,rverifica.nombrearchivo);
END IF;

END IF;


return respuesta;
END;
$function$
