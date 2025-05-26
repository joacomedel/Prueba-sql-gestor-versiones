CREATE OR REPLACE FUNCTION public.far_generaarchivotrazabilidad(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  ptipoarchivo alias for $1;
  respuesta varchar;
  cursorarchi REFCURSOR;
  contenido varchar;
  separador varchar;
  enter varchar;
  fila varchar;
  relem RECORD;
  idarchivo BIGINT;
  rusuario RECORD;
   
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

IF ptipoarchivo = '#VF_RECIBIR' THEN

INSERT INTO far_archivotrazabilidad(atratipoarchivo,idusuario) 
(SELECT ptipoarchivo,rusuario.idusuario
 from far_articulotrazabilidad
  NATURAL JOIN far_articulotrazabilidadestado
  join far_precargarpedidocompcatalogo USING(idprecargarpedidocompcatalogo,idcentroprecargarpedidocompcatalogo)
  natural join prestador 
  WHERE idarticulotrazabilidadestadotipos = 2 
  AND nullvalue(atefechafin) 
LIMIT 1
);
 IF FOUND THEN 
	idarchivo = currval('far_archivotrazabilidad_idarchivostrazabilidad_seq'::regclass);

	OPEN cursorarchi FOR SELECT atcodigotrazabilidad,atcodigobarragtin
					,atlote,to_char(atvencimiento,'dd/mm/yy') as atvencimiento
					 ,''::varchar as fecharemito,''::varchar as nroremito
					 ,CASE WHEN nullvalue(fechaemision) THEN '' ELSE to_char(fechaemision,'dd/mm/yyyy') END as fechaemision
					 ,concat(letra,numfactura) as numfactura, pdescripcion
					 ,replace(pcuit,'-','') as pcuit,gln,'DROGUERIA'::varchar as tipoproveedor, ''::varchar as tlproveedor,''::varchar as dirproveedor
					 ,far_articulotrazabilidad.idarticulotraza
					 ,far_articulotrazabilidad.idcentroarticulotraza
					 from far_articulotrazabilidad
                                         NATURAL JOIN far_articulotrazabilidadestado
					 join far_precargarpedidocompcatalogo USING(idprecargarpedidocompcatalogo,idcentroprecargarpedidocompcatalogo)
					 natural join prestador 
					WHERE idarticulotrazabilidadestadotipos = 2 AND nullvalue(atefechafin);
	FETCH cursorarchi into relem;
	    WHILE  found LOOP
		fila = concat(relem.atcodigotrazabilidad, separador 
		      ,relem.atcodigobarragtin , separador
		      , relem.atlote ,separador
		       , relem.atvencimiento ,separador
		      , relem.fecharemito , separador);
		       
		fila = concat(fila 
			,relem.nroremito , separador
			, relem.fechaemision, separador
			, relem.numfactura, separador
			, relem.pdescripcion, separador
			, relem.pcuit , separador
			, relem.gln , separador
			, relem.tipoproveedor , separador
			,relem.tlproveedor , separador
			, relem.dirproveedor 
		     , enter);
		contenido = concat(contenido ,fila);

		INSERT INTO far_archivotrazabilidadarticulo(idarchivostrazabilidad,idcentroarchivostrazabilidad,idarticulotraza,idcentroarticulotraza,atalinea)
		VALUES(idarchivo,centro(),relem.idarticulotraza,relem.idcentroarticulotraza,fila);

	    FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;

	END IF;
END IF;

IF ptipoarchivo = '#VF_VENTAPACIENTE' THEN
-- codigo de trazabilidad, gtin medicamento, lote, vencimiento, fecha factura (no ob.), factura (no ob.), RNOS, afiliado
INSERT INTO far_archivotrazabilidad(atratipoarchivo,idusuario) 
(SELECT ptipoarchivo,rusuario.idusuario
  from far_articulotrazabilidad 
  join far_articulocomprobantecompra USING(idarticulocomprobantecompra,idcentroarticulocomprobantecompra) 
  natural join far_afiliado 
  JOIN far_ordenventaitem USING(idordenventaitem,idcentroordenventaitem) 
  JOIN far_ordenventa USING(idordenventa,idcentroordenventa) 
 WHERE (idarticulotraza,idcentroarticulotraza) NOT IN 
  (SELECT idarticulotraza,idcentroarticulotraza
  FROM far_archivotrazabilidadarticulo
  NATURAL JOIN far_archivotrazabilidad 
  WHERE far_archivotrazabilidad.atratipoarchivo =  ptipoarchivo
   )
   LIMIT 1
   );
 IF FOUND THEN 
	idarchivo = currval('far_archivotrazabilidad_idarchivostrazabilidad_seq'::regclass);

		OPEN cursorarchi FOR SELECT atcodigotrazabilidad,atcodigobarragtin,atlote,to_char(atvencimiento,'dd/mm/yy') as atvencimiento 
						,CASE WHEN nullvalue(idordenventa) THEN ''::varchar ELSE to_char(ovfechaemision,'dd/mm/yyyy') END as fechaemision 
						,CASE WHEN nullvalue(idordenventa) THEN ''::varchar ELSE concat('OV','-', trim(to_char(idcentroordenventa,'0000')), trim(to_char(idordenventa,'000000000000'))) END as numcomprobante 
						,CASE WHEN nullvalue(osrnos) THEN '' ELSE osrnos::varchar END ::varchar as codigornos,aidafiliadoobrasocial
						,idarticulotraza,idcentroarticulotraza
						 from far_articulotrazabilidad 
						 NATURAL JOIN  far_afiliado
						 NATURAL JOIN far_obrasocial
						 JOIN far_ordenventaitem USING(idordenventaitem,idcentroordenventaitem) 
						 JOIN far_ordenventa USING(idordenventa,idcentroordenventa) 
						 WHERE (idarticulotraza,idcentroarticulotraza) NOT IN 
							(SELECT idarticulotraza,idcentroarticulotraza
							 FROM far_archivotrazabilidadarticulo
							 NATURAL JOIN far_archivotrazabilidad 
							 WHERE far_archivotrazabilidad.atratipoarchivo =  ptipoarchivo
							)
						;
		FETCH cursorarchi into relem;
		    WHILE  found LOOP

			fila = concat(relem.atcodigotrazabilidad , separador 
			      , relem.atcodigobarragtin , separador
			       ,relem.atlote , separador
			       , relem.atvencimiento , separador
			      , relem.fechaemision , separador)
			       ;
			       
			fila = concat(fila 
				, relem.numcomprobante , separador
				, relem.codigornos , separador
				,relem.aidafiliadoobrasocial 
			     , enter);
			contenido = concat(contenido, fila);

			INSERT INTO far_archivotrazabilidadarticulo(idarchivostrazabilidad,idcentroarchivostrazabilidad,idarticulotraza,idcentroarticulotraza)
			VALUES(idarchivo,centro(),relem.idarticulotraza,relem.idcentroarticulotraza);

		    FETCH cursorarchi INTO relem;
		    END LOOP;
		CLOSE cursorarchi;

		END IF;

END IF;


IF ptipoarchivo = '#VF_A_RECIBIR' THEN

INSERT INTO far_archivotrazabilidad(atratipoarchivo,idusuario) 
(SELECT ptipoarchivo,rusuario.idusuario
 );
	IF FOUND THEN 
		idarchivo = currval('far_archivotrazabilidad_idarchivostrazabilidad_seq'::regclass);

		
	END IF;

END IF;

contenido = concat(ptipoarchivo , enter, contenido);
UPDATE far_archivotrazabilidad SET atracontenidoenvio = contenido 
WHERE idarchivostrazabilidad = idarchivo AND idcentroarchivostrazabilidad = centro();

respuesta = concat(idarchivo,'-' ,centro());


return respuesta;
END;
$function$
