CREATE OR REPLACE FUNCTION public.far_generaarchivoliquidacionrecetas(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  ptipoarchivo alias for $1;
  respuesta varchar;
  cursorarchi REFCURSOR;
  contenido varchar;
  separador varchar;
  encabezado varchar;
  mesaniofacturacion varchar;
  finarchivo varchar;
  enter varchar;
  fila varchar;
  relem RECORD;
  idarchivo BIGINT;
  rusuario RECORD;
  nrodetalle BIGINT;
  sumimportecoseguro double precision;
  sumimportesincoseguro double precision;
   
BEGIN
separador = '';
respuesta = '';
contenido = '';
encabezado = '';
finarchivo = '';
sumimportesincoseguro = 0;
sumimportecoseguro = 0;

enter = '
';
nrodetalle = 0;

SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

IF ptipoarchivo = 'ISSN_Informar' THEN


INSERT INTO far_archivotrazabilidad(atratipoarchivo,idusuario) 
(SELECT ptipoarchivo,rusuario.idusuario 
);

idarchivo = currval('far_archivotrazabilidad_idarchivostrazabilidad_seq'::regclass);

OPEN cursorarchi FOR SELECT DISTINCT '30590509643' as cuit,'01' as consultorio
--,ROW_NUMBER() OVER (ORDER BY nroordenconformato)
,sum(ovicantidad) as cantidadtroqueles
,sum(CASE WHEN fv.tipofactura='NC' THEN oviprecioventa *-1 ELSE oviprecioventa END  * ovicantidad) as importesincoseguro
,sum((CASE WHEN fv.tipofactura='NC' THEN oviprecioventa *-1 ELSE oviprecioventa END  * ovicantidad) - CASE WHEN fv.tipofactura='NC' THEN fovii.oviimonto *-1 ELSE fovii.oviimonto END) as importecoseguro
,concat(to_char(o.idcentroordenventa, '0000') , '-' ,  to_char(o.idordenventa, '00000000')) AS nroordenconformato
,concat(fv.tipofactura,to_char(fv.nrosucursal, '0000') , '-' ,  to_char(fv.nrofactura, '00000000')) AS nrofacturaconformato
,to_char(lfechahasta,'mmYYYY') as mesaniofacturacion
,CASE WHEN pcporcentaje = 0.7 THEN '051' WHEN pcporcentaje = 0.8 THEN '138' WHEN pcporcentaje = 1.0 THEN '048' ELSE '001' END as nrotipopresentacion
FROM far_ordenventa as o NATURAL JOIN  far_ordenventaitem as fovi NATURAL JOIN  far_ordenventaitemimportes as fovii
JOIN far_liquidacionitemovii as fliovii USING(idordenventaitem,idcentroordenventaitem, idordenventaitemimporte ,idcentroordenventaitemimporte)
JOIN far_liquidacionitems as fli USING(idliquidacionitem,idcentroliquidacionitem)
NATURAL JOIN far_liquidacion
LEFT JOIN temp_configuraarchivotrazabilidad USING(idliquidacion,idcentroliquidacion)
NATURAL JOIN far_obrasocial as os
JOIN far_configura_reporte cr ON cr.idobrasocial = os.idobrasocial AND cr.idvalorcajacoseguro = fovii.idvalorescaja
NATURAL JOIN far_articulo
JOIN far_ordenventaitemitemfacturaventa  as fovifv ON (fovi.idordenventaitem=fovifv.idordenventaitem and fovi.idcentroordenventaitem=fovifv.idcentroordenventaitem ) 
NATURAL JOIN facturaventa fv
LEFT JOIN facturaventa_quitardeliq as fvql ON (fv.nrofactura=fvql.nrofactura  and fv.tipocomprobante=fvql.tipocomprobante and fv.nrosucursal=fvql.nrosucursal and fv.tipofactura=fvql.tipofactura )
WHERE far_liquidacion.idliquidacion= 1593 
and far_liquidacion.idcentroliquidacion=99
AND nullvalue(anulada) AND
(case when cr.idobrasocial<>3 or cr.idobrasocial<>1 then fv.tipofactura<>'NC' ELSE fv.tipofactura='NC' OR fv.tipofactura='FA' end) AND nullvalue(fvql.nrofactura)
GROUP BY nrotipopresentacion,mesaniofacturacion,nrofacturaconformato,nroordenconformato
ORDER BY nrotipopresentacion,mesaniofacturacion,nrofacturaconformato,nroordenconformato
Limit 2;
	FETCH cursorarchi into relem;
	    WHILE  found LOOP
                nrodetalle = nrodetalle + 1;
		fila = concat(relem.cuit, separador 
		      ,relem.consultorio , separador
		      ,trim(to_char(nrodetalle,'000')),separador
		      ,trim(to_char(relem.cantidadtroqueles,'000000')),separador
		      ,trim(to_char(relem.importesincoseguro*100,'000000000000000')),separador
		      ,trim(to_char(relem.importecoseguro*100,'000000000000000')),separador
		      ,relem.nrotipopresentacion , separador);
		       
		contenido = concat(contenido,fila,enter);
		
		sumimportecoseguro = sumimportecoseguro + relem.importecoseguro;
		sumimportesincoseguro = sumimportesincoseguro + relem.importesincoseguro;
                mesaniofacturacion = relem.mesaniofacturacion;

		INSERT INTO far_archivotrazabilidadordenventa(idarchivostrazabilidad,idcentroarchivostrazabilidad,nroordenconformato,nrofacturaconformato,atalinea)
		VALUES(idarchivo,centro(),relem.nroordenconformato,relem.nrofacturaconformato,fila);

	    FETCH cursorarchi INTO relem;
	    END LOOP;
	CLOSE cursorarchi;

	END IF;


encabezado = concat(mesaniofacturacion,separador
		     ,'AJ',separador
		     ,to_char(now(),'YYYYmmdd'),separador
                     ,to_char(now(),'hhmmss'),separador
   );
finarchivo = concat('F',separador
		,trim(to_char(nrodetalle,'0000')),separador
		,trim(to_char(sumimportesincoseguro*100,'000000000000000')),separador
		,trim(to_char(sumimportecoseguro*100,'000000000000000')),separador
		);
contenido = concat(encabezado , enter, contenido, finarchivo);
UPDATE far_archivotrazabilidad SET atracontenidoenvio = contenido 
WHERE idarchivostrazabilidad = idarchivo AND idcentroarchivostrazabilidad = centro();

respuesta = concat(idarchivo,'-' ,centro());


return respuesta;
END;
$function$
