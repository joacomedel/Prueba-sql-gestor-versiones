CREATE OR REPLACE FUNCTION public.afiliaciones_subsidiofalle_darcambiosdesdeweb(pfiltros character varying)
 RETURNS text
 LANGUAGE plpgsql
AS $function$/* Recupera la informacion cargada desde SigesWeb, sobre subsidios por fallecimiento */

DECLARE
	rfiltros record;
	rusuario RECORD;
	resultado TEXT;
	vfila TEXT;
	rpersona RECORD;
	rweb RECORD;
	vnocambio boolean;
	vnofilacambio boolean;
	vcolor TEXT;
        vbgcolor TEXT;

BEGIN
SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
IF NOT FOUND THEN 
   rusuario.idusuario = 25;
END IF;

vnocambio= true;

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
vcolor ='#ca9f5e';
vbgcolor = '';


SELECT INTO rpersona *  
FROM persona 
NATURAL JOIN ( 
select nrodoctitu as nrodoc, tipodoctitu as tipodoc, text_concatenar(concat('<tr>',concat('<td>',tipodocdes,':',adsnrodoc,'</td>','<td>',adsnombres,' ',adsapellido,'</td>','<td>',adsvinculo,'</td>','<td>',adsporciento,'</td>','<td>',adsfechaingreso,'</td>'),'</tr>')) as textonuevo
FROM w_afiliacion_declara_subsidio
JOIN (SELECT descrip as tipodocdes,tipodoc FROM  tiposdoc) as tipodoc  ON (tipodoc = adstipodoc)
LEFT JOIN w_afiliacion_declara_subsidio_procesado USING(idafiliaciondeclarasubsidio)
WHERE nullvalue(adsfechafinvigencia) AND nullvalue(adspfechaproceso)
GROUP BY nrodoctitu,tipodoctitu
 ) as cargado 
LEFT JOIN (SELECT nrodoctitu as nrodoc, tipodoctitu as tipodoc, text_concatenar(concat('<tr>',concat('<td>',tipodocdes,':',nrodoc,'</td>','<td>',nombres,' ',apellido,'</td>','<td>',vinculo,'</td>','<td>',porcent,'</td>','<td>',now(),'</td>'),'</tr>')) as textoactual


			FROM declarasubs
	                NATURAL JOIN (SELECT descrip as tipodocdes,tipodoc FROM  tiposdoc) as tipodoc  
                        GROUP BY nrodoctitu,tipodoctitu  
	      ) as infodeclarasubs USING (nrodoc,tipodoc)

WHERE nrodoc = trim(rfiltros.nrodoc) AND tipodoc = rfiltros.tipodoc AND (nrodoc,tipodoc) IN (
select nrodoctitu,tipodoctitu 
FROM w_afiliacion_declara_subsidio
LEFT JOIN w_afiliacion_declara_subsidio_procesado USING(idafiliaciondeclarasubsidio)
WHERE nullvalue(adsfechafinvigencia) AND nullvalue(adspfechaproceso)
);

resultado = concat('<div><span><b>Cambios en la Declaracion Jurada de ',trim(rfiltros.nrodoc),' .</b></span>');
resultado = concat(resultado,'<table border="1" style="border-collapse:collapse;border-color:#ddd;" ><tr><th>Tipo y Nro.Documento</th><th>Nombre y Apellido</th><th>Vinculo</th><th>Porciento</th><th>Fecha Carga</th></tr>');

resultado = concat(resultado,'<tr><td colspan=5> Actualmente </td> </tr>',rpersona.textoactual);
resultado = concat(resultado,'<tr><td colspan=5> Presenta Ahora </td> </tr>',rpersona.textonuevo);


RAISE NOTICE 'Lala (%),(%),(%)',rfiltros.nrodoc,rfiltros.tipodoc,rpersona;
    
resultado = concat(resultado,'</table> </div>'::text);
return resultado;
END;
$function$
