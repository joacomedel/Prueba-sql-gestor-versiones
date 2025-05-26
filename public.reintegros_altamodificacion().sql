CREATE OR REPLACE FUNCTION public.reintegros_altamodificacion()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
       
--RECORD
	rpersona RECORD;
	rreintegro RECORD; 
        aux RECORD;
	
--VARIABLES
	elidrecepcion BIGINT;
	elreintegro BIGINT;
	
	
BEGIN
  SELECT INTO rpersona  temporden.nrodoc AS nrodocbenefre, temporden.tipodoc AS tipodocbenefre, persona.barra AS barrabenefre, persona.nombres, persona.apellido, CASE WHEN nullvalue(nrodoctitu) THEN temporden.nrodoc ELSE nrodoctitu END AS nrodoctitu, CASE WHEN nullvalue(tipodoctitu) THEN temporden.tipodoc ELSE tipodoctitu END AS tipodoctitu, CASE WHEN nullvalue(tipodoctitu) THEN persona.nombres ELSE p2.nombres END AS nombretitu
, CASE WHEN nullvalue(tipodoctitu) THEN persona.apellido ELSE p2.apellido END AS apellidotitu
, CASE WHEN nullvalue(tipodoctitu) THEN persona.barra ELSE p2.barra END AS barratitu
,nroanticipo,idcentroregional as idcentroregionalanticipo,anioanticipo
FROM temporden NATURAL JOIN persona LEFT JOIN benefsosunc  USING(nrodoc, tipodoc) 
LEFT JOIN persona AS p2 ON (nrodoctitu=p2.nrodoc AND tipodoctitu=p2.tipodoc);

 INSERT INTO comprobante(fechahora) VALUES (now());
 INSERT INTO recepcion(idcomprobante,idtiporecepcion,fecha,nombre,apellido,idcorreo) 
 VALUES (currval('"public"."comprobante_idcomprobante_seq"'::text::regclass),5,NOW(),rpersona.nombres,rpersona.apellido,0);
 elidrecepcion = currval('"public"."recepcion_idrecepcion_seq"'::text::regclass);
 INSERT INTO recreintegro(idrecepcion,nrodoc,barra,nombreaf,apellidoaf,idcentroreintegro)
 VALUES (elidrecepcion,rpersona.nrodoctitu,rpersona.barratitu,rpersona.nombretitu,rpersona.apellidotitu,centro());
 
 INSERT INTO reintegroestudio(idestudio,idrecepcion,cantidad) (
 SELECT tipoprestacion, elidrecepcion, sum(tempitems.cantidad) as cantidad
	FROM tempitems 
	GROUP BY tipoprestacion
);

  PERFORM insertarreintegro3(elidrecepcion::integer,2,rpersona.nrodocbenefre,rpersona.barrabenefre);
  
  SELECT INTO aux * FROM reintegro WHERE idrecepcion = elidrecepcion AND idcentrorecepcion  = centro();

  CREATE TEMP TABLE tempreintegromodificado (anio INTEGER,	nroreintegro INTEGER,	idcentroregional INTEGER,	tipoprestacion INTEGER,	importe DOUBLE PRECISION, observacion VARCHAR, prestacion VARCHAR, cantidad INTEGER);

  INSERT INTO tempreintegromodificado(nroreintegro,anio,idcentroregional,tipoprestacion,importe,observacion,prestacion,cantidad) 
  SELECT nroreintegro,anio,idcentroregional,tipoprestacion,importe,observacion,prestacion,cantidad
  FROM reintegroprestacion
  WHERE nroreintegro= aux.nroreintegro AND anio=aux.anio AND idcentroregional=aux.idcentroregional;
	
--KR 23-11-22 si es un reintegro de anticipo lleno la tabla anticiporeintegro
  IF (rpersona.nroanticipo IS NOT NULL) THEN
    INSERT INTO anticiporeintegro(nroreintegro,anioreintegro,idcentroreintegro,anioanticipo,nroanticipo,fechaasociacion,idcentroanticipo) 
    VALUES(aux.nroreintegro,aux.anio,aux.idcentroregional,rpersona.anioanticipo,rpersona.nroanticipo,NOW(),rpersona.idcentroregionalanticipo);
  END IF;
 
return CONCAT(aux.nroreintegro,'-',aux.anio,'-',aux.idcentroregional,'-',elidrecepcion);
END;$function$
