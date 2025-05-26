CREATE OR REPLACE FUNCTION public.afiliaciones_darcambiosdesdeweb(pfiltros character varying)
 RETURNS text
 LANGUAGE plpgsql
AS $function$/* Ingresa la informacion de una alerta */

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
NATURAL JOIN (SELECT nrodoc,tipodoc,idosexterna,nroosexterna, expendio_tiene_amuc(nrodoc,tipodoc) as mutual 
			FROM afilsosunc
			WHERE nrodoc = trim(rfiltros.nrodoc) AND tipodoc = rfiltros.tipodoc
	       UNION SELECT nrodoc,tipodoc,CASE WHEN nullvalue(idosexterna) OR btrim(idosexterna) = ''  OR btrim(idosexterna) = 'null' THEN '0' ELSE idosexterna END as idosexterna,nroosexterna,expendio_tiene_amuc(nrodoc,tipodoc) FROM benefsosunc WHERE nrodoc = trim(rfiltros.nrodoc) AND tipodoc = rfiltros.tipodoc
	      ) as infoosexterna
NATURAL JOIN (SELECT descrip as tipodocdes,tipodoc FROM  tiposdoc) as tipodoc  
NATURAL JOIN (SELECT descrip as estadocivildescrip,estcivil FROM testadocivil) as testadocivil  
LEFT JOIN (SELECT descrip as osexternadescrip,idosexterna FROM osexterna) as osexterna USING(idosexterna)
NATURAL JOIN (SELECT localidaddescrip,idlocalidad,nro,barrio,calle,iddireccion,idcentrodireccion,idprovincia,piso,dpto,provinciadescrip
		FROM direccion 
		NATURAL JOIN (SELECT descrip as localidaddescrip,idlocalidad FROM localidad ) as l
		NATURAL JOIN (SELECT descrip as provinciadescrip,idprovincia FROM provincia ) as p
		 ) as direccion

WHERE nrodoc = trim(rfiltros.nrodoc) AND tipodoc = rfiltros.tipodoc;

SELECT INTO rweb * FROM w_afiliaciondatos 
NATURAL JOIN (SELECT descrip as tipodocdes,tipodoc as idtiposdoc FROM  tiposdoc) as tipodoc  
LEFT JOIN (SELECT descrip as localidaddescrip,idlocalidad FROM localidad) as localidad  USING(idlocalidad)
LEFT JOIN (SELECT descrip as provinciadescrip,idprovincia FROM provincia ) as provincia USING(idprovincia)
LEFT JOIN (SELECT descrip as estadocivildescrip,estcivil::integer as idtestadocivil FROM testadocivil) as testadocivil USING(idtestadocivil)
LEFT JOIN (SELECT descrip as osexternadescrip,idosexterna FROM osexterna) as osexterna USING(idosexterna)
WHERE nrodoc =  trim(rfiltros.nrodoc) AND idtiposdoc = rfiltros.tipodoc;

resultado = concat('<div><span><b>Cambios en la Declaracion Jurada de ',trim(rfiltros.nrodoc),' .</b></span>');
resultado = concat(resultado,'<table border="1" style="border-collapse:collapse;border-color:#ddd;" ><tr><th>Dato</th><th>Siges</th><th>Web</th></tr>');

RAISE NOTICE 'Lala (%),(%),(%)',rfiltros.nrodoc,rfiltros.tipodoc,rpersona;
	
	IF btrim(upper(rpersona.nombres)) <> btrim(upper(rweb.adnombre))  THEN
		vnocambio = vnocambio AND false;
		vbgcolor = concat(' bgcolor="',vcolor,'"');

	END IF;
	vfila = concat('<tr',vbgcolor,'><td>Nombre: </td><td>',rpersona.nombres,'</td><td>',rweb.adnombre,'</td></tr>');
	resultado = concat(resultado,vfila,' '::text);vbgcolor=''; 

	IF btrim(upper(rpersona.apellido)) <> btrim(upper(rweb.adapellido))  THEN
		vnocambio = vnocambio AND false;
		vbgcolor = concat(' bgcolor="',vcolor,'"');
	END IF;
	vfila = concat('<tr',vbgcolor,'><td>Apellido: </td><td>',rpersona.apellido,'</td><td>',rweb.adapellido,'</td></tr>');
	resultado = concat(resultado,vfila,' '::text);vbgcolor=''; 

	IF btrim(upper(rpersona.sexo)) <> btrim(upper(rweb.adsexo)) THEN
		vnocambio = vnocambio AND false;
		vbgcolor = concat(' bgcolor="',vcolor,'"');
	END IF;
	vfila = concat('<tr',vbgcolor,'><td>Sexo: </td><td>',rpersona.sexo,'</td><td>',rweb.adsexo,'</td></tr>');vbgcolor='';
	resultado = concat(resultado,vfila,' '::text);vbgcolor=''; 

	IF rpersona.fechanac <> rweb.adfechanac THEN
		vnocambio = vnocambio AND false;
		vbgcolor = concat(' bgcolor="',vcolor,'"');
	END IF;
	vfila = concat('<tr',vbgcolor,'><td>Fecha Nacimiento: </td><td>',rpersona.fechanac,'</td><td>',rweb.adfechanac,'</td></tr>');
	resultado = concat(resultado,vfila,' '::text);vbgcolor=''; 

	IF rpersona.estcivil <> rweb.idtestadocivil THEN
		vnocambio = vnocambio AND false;
		vbgcolor = concat(' bgcolor="',vcolor,'"');
	END IF;
	vfila = concat('<tr',vbgcolor,'><td>Estado Civil: </td><td>',rpersona.estadocivildescrip,'</td><td>',rweb.estadocivildescrip,'</td></tr>');
	resultado = concat(resultado,vfila,' '::text);vbgcolor='';

	IF concat(btrim(upper(CASE WHEN rpersona.carct = 0 THEN '' ELSE rpersona.carct END)),replace(upper(rpersona.telefono),' ','')) <> concat(replace(upper(rweb.adtelfijo),' ',''),replace(upper(rweb.adcel),' ','')) THEN
		vnocambio = vnocambio AND false;
		vbgcolor = concat(' bgcolor="',vcolor,'"');
		RAISE NOTICE 'telefono (%),(%),(%)',concat(btrim(upper(CASE WHEN rpersona.carct = 0 THEN '' ELSE rpersona.carct END)),btrim(upper(rpersona.telefono))),concat(btrim(upper(rweb.adtelfijo)),btrim(upper(rweb.adcel))),rweb;
	END IF;
	vfila = concat('<tr',vbgcolor,'><td>Telefono: </td><td>',concat(CASE WHEN rpersona.carct = 0 THEN '' ELSE rpersona.carct END,' ',rpersona.telefono),'</td><td>',concat(rweb.adtelfijo,' ',rweb.adcel),'</td></tr>');
	resultado = concat(resultado,vfila,' '::text);vbgcolor=''; 

	IF btrim(upper(rpersona.email)) <> btrim(upper(rweb.ademail)) THEN
		vnocambio = vnocambio AND false;
		vbgcolor = concat(' bgcolor="',vcolor,'"');
	END IF;
	vfila = concat('<tr',vbgcolor,'><td>Email: </td><td>',rpersona.email,'</td><td>',rweb.ademail,'</td></tr>');
	resultado = concat(resultado,vfila,' '::text);vbgcolor=''; 

	IF rpersona.idosexterna <> rweb.idosexterna THEN
		vnocambio = vnocambio AND false;
		vbgcolor = concat(' bgcolor="',vcolor,'"');
	END IF;
	
	vfila = concat('<tr',vbgcolor,'><td>Otra Obra Social: </td><td>',rpersona.osexternadescrip,'</td><td>',rweb.osexternadescrip,'</td></tr>');
	resultado = concat(resultado,vfila,' '::text);vbgcolor=''; 

	
	IF not (nullvalue(rpersona.nroosexterna) AND rweb.adotraos = '') THEN 
		IF btrim(upper(rpersona.nroosexterna)) <> btrim(upper(rweb.adotraos)) 
                 OR (  nullvalue(btrim(upper(rpersona.nroosexterna)) <> btrim(upper(rweb.adotraos))) ) THEN
			vnocambio = vnocambio AND false;
			vbgcolor = concat(' bgcolor="',vcolor,'"');
		END IF;
	END IF;
	vfila = concat('<tr',vbgcolor,'><td>Nro Otra OS: </td><td>',rpersona.nroosexterna,'</td><td>',rweb.adotraos,'</td></tr>');
	resultado = concat(resultado,vfila,' '::text);vbgcolor=''; 

	IF rpersona.mutual <> rweb.adamuc THEN
		vnocambio = vnocambio AND false;
		vbgcolor = concat(' bgcolor="',vcolor,'"');
	END IF;
	vfila = concat('<tr',vbgcolor,'><td>Amuc?: </td><td>',CASE WHEN rpersona.mutual THEN 'SI' ELSE 'NO' END,'</td><td>',CASE WHEN rweb.adamuc THEN 'SI' ELSE 'NO' END,'</td></tr>');
	resultado = concat(resultado,vfila,' '::text);vbgcolor=''; 

	
	IF upper(concat(rpersona.nro,'|',btrim(rpersona.calle),'|',rpersona.idlocalidad,'|',rpersona.idprovincia,'|',btrim(rpersona.barrio),'|',btrim(rpersona.piso),'|',btrim(rpersona.dpto))) <> 
	upper(concat(rweb.adnumero,'|',btrim(rweb.adcalle),'|',rweb.idlocalidad,'|',rweb.idprovincia,'|',btrim(rweb.adbarrio),'|',btrim(rweb.adpiso),'|',btrim(rweb.addepartamento))) THEN
		vnocambio = vnocambio AND false;
		vbgcolor = concat(' bgcolor="',vcolor,'"');
	END IF;
	RAISE NOTICE 'cambio direccion (global %),( dato %)',vnocambio,vnofilacambio;
	vfila = concat('<tr',vbgcolor,'><td>Direccion: </td><td>',concat(rpersona.barrio,'&nbsp; ',rpersona.calle,'&nbsp; ',rpersona.nro,'&nbsp; ',rpersona.localidaddescrip,'&nbsp; ',rpersona.provinciadescrip,'&nbsp; ',rpersona.piso,'&nbsp; ',rpersona.dpto),'</td>
		       <td>',concat(rweb.adbarrio,'&nbsp; ',rweb.adcalle,'&nbsp; ',rweb.adnumero,'&nbsp; ',rweb.localidaddescrip,'&nbsp; ',rweb.provinciadescrip,'&nbsp; ',rweb.adpiso,'&nbsp; ',rweb.addepartamento),'</td></tr>');
	resultado = concat(resultado,vfila,' '::text);vbgcolor=''; 

	IF not nullvalue(rweb.adbaja) THEN
		vnocambio = vnocambio AND false;
		vbgcolor = concat(' bgcolor="',vcolor,'"');
	END IF;
	
	vfila = concat('<tr',vbgcolor,'><td>Desafiliar:</td><td colspan=2>',CASE WHEN not nullvalue(rweb.adbaja) THEN 'Se va a Desafiliar' ELSE '' END,'</td></tr>');
	resultado = concat(resultado,vfila,' '::text); vbgcolor=''; 
    
resultado = concat(resultado,'</table> </div>'::text);
resultado = concat(CASE WHEN vnocambio THEN 'NO' ELSE 'SI' END,'#',resultado);
return resultado;
END;
$function$
