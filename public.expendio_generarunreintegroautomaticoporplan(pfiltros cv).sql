CREATE OR REPLACE FUNCTION public.expendio_generarunreintegroautomaticoporplan(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
   
    cursorplanes refcursor;
    rplancobpersona RECORD;
    rregistroaux RECORD;
    idrecepciont integer=0; 
    aux RECORD;
 --   rcuentas RECORD;
--   rbeneficiario RECORD;
--   reintegroexiste RECORD;

     rfiltros record;
     rinforme record;
     rreciboorden record;
     rcentroregional record;
     resposibleconsumo record;

BEGIN
	EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

	select  into rcentroregional  * from centroregional  WHERE centroregional.idcentroregional = centro();

	CREATE TEMP TABLE temporden(nrodoc varchar(8),tipodoc int  NOT NULL,numorden bigint , ctroorden integer, centro int4 NOT NULL,recibo boolean,tipo int8,amuc float ,afiliado float ,sosunc float,enctacte boolean,formapago varchar,idprestador INTEGER,ordenreemitida INTEGER,centroreemitida INTEGER,nromatricula INTEGER,cantordenes INTEGER, idasocconv BIGINT,nroreintegro BIGINT, anio INTEGER,autogestion BOOLEAN DEFAULT false,idcentroreintegro INTEGER ) WITHOUT OIDS;
	CREATE TEMP TABLE tempreintegromodificado (anio INTEGER,	nroreintegro INTEGER,	idcentroregional INTEGER,	tipoprestacion INTEGER,	importe DOUBLE PRECISION, observacion VARCHAR, prestacion VARCHAR, cantidad INTEGER);
	CREATE TEMP TABLE tempitems(cantidad int4 NOT NULL,importe float NOT NULL,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,idpractica varchar,idplancob varchar,auditada boolean,porcentaje integer,idpiezadental varchar,idzonadental varchar,idletradental varchar,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4,tipoprestacion integer,obsprestacion varchar) WITHOUT OIDS;


	CREATE TEMP TABLE esposibleelconsumo (    idpractica character varying,    idplancobertura character varying,    idnomenclador character varying,    auditoria boolean,    cobertura integer,    idcapitulo character varying,     idsubcapitulo character varying,     idplancoberturas bigint,    ppccantpractica integer,     ppcperiodo character varying,     ppccantperiodos integer,     ppclongperiodo integer,     ppcprioridad integer,     idconfiguracion bigint,    serepite boolean,    ppcperiodoinicial integer,    ppcperiodofinal integer,    rcantidadconsumida integer,    rcantidadrestante integer,    nivel integer,    fechadesde date,    fechahasta date,    pimportepractica double precision,    pimporteamuc double precision,    pimporteafiliado double precision,    pimportesosunc double precision,    coberturaamuc double precision,    nrocuentac character varying,    idesposibleelconsumo integer,    esreintegro  boolean default true		,    coberturasosunc double precision);
  /* Por cada plan de cobertura activo o donde la fecha fin del plan es null */
   OPEN cursorplanes for select * 
	FROM plancobpersona 
	NATURAL JOIN reintegro_configuraemisionautomatica as cea
	NATURAL JOIN persona   
	LEFT JOIN 
	( SELECT reintegro.* FROM reintegro 
		NATURAL JOIN reintegroprestacion 
		NATURAL JOIN reintegro_configuraemisionautomatica as cea
                JOIN restados USING(nroreintegro,anio,idcentroregional)
		WHERE nullvalue(refechafin) AND tipoestadoreintegro <> 5 --MaLaPi, si el reintegro esta rechazado no vale
                 AND (date_part('year',rfechaingreso) =rfiltros.anio and date_part('month',rfechaingreso) =rfiltros.mes )
		AND cea.idplancoberturas=rfiltros.idplancoberturas
	) as existereintegro USING(nrodoc,tipodoc)
	WHERE cea.idplancoberturas=rfiltros.idplancoberturas 
	and nullvalue(nroreintegro)
	and ((pcpfechafin >  NOW())  or ( pcpfechafin is null  ))
	--LIMIT 3
        ;
    FETCH cursorplanes into rplancobpersona;
    WHILE  found LOOP

	-- Verifico el consumo para ver si se puede emitir la orden tras el reintegro
	DELETE FROM esposibleelconsumo;
	PERFORM expendio_verificar_consumo(rplancobpersona.idnomenclador,rplancobpersona.idcapitulo,rplancobpersona.idsubcapitulo,rplancobpersona.idpractica,rplancobpersona.idplancoberturas_expendio,rplancobpersona.nrodoc,rplancobpersona.tipodoc,rplancobpersona.idasocconv_expendio);
	SELECT INTO resposibleconsumo * FROM esposibleelconsumo as e  WHERE e.rcantidadrestante > 0  AND e.fechadesde <= current_date  AND e.fechahasta >= current_date  ORDER BY nivel DESC,ppcprioridad;
	IF FOUND THEN 

         -- Ingreso la recepcion 
       	 INSERT INTO comprobante(fechahora) VALUES (now());
         INSERT INTO recepcion(idcomprobante,idtiporecepcion,fecha,nombre,apellido,idcorreo) 
         VALUES (currval('"public"."comprobante_idcomprobante_seq"'::text::regclass),rplancobpersona.idtiporecepcion,NOW(),rplancobpersona.nombres,rplancobpersona.apellido,0);
         idrecepciont = currval('"public"."recepcion_idrecepcion_seq"'::text::regclass);
         INSERT INTO recreintegro(idrecepcion,nrodoc,barra,localidad,nombreaf,apellidoaf,idcentroreintegro)
         VALUES (idrecepciont,rplancobpersona.nrodoc,rplancobpersona.barra,rcentroregional.crdescripcion,rplancobpersona.nombres,rplancobpersona.apellido,rcentroregional.idcentroregional);
	 INSERT INTO reintegroestudio(idestudio,idrecepcion,cantidad) VALUES (rplancobpersona.idestudio,idrecepciont,1);
	 PERFORM insertarreintegro3(idrecepciont,2,rplancobpersona.nrodoc,rplancobpersona.barra);
         UPDATE reintegro SET rfechaingreso = to_date(concat('01','-',rfiltros.mes,'-',rfiltros.anio), 'DD-MM-YYYY')  WHERE idrecepcion = idrecepciont AND idcentrorecepcion  = centro();
         SELECT INTO aux * FROM reintegro WHERE idrecepcion = idrecepciont AND idcentrorecepcion  = centro();

	--- Emito la Orden
	DELETE FROM temporden;
	DELETE FROM tempreintegromodificado;
	DELETE FROM tempitems;

	INSERT INTO temporden(nrodoc,tipodoc,numorden,ctroorden,centro,tipo,amuc,afiliado,sosunc,formapago,idprestador,ordenreemitida,centroreemitida,nromatricula,cantordenes,idasocconv,nroreintegro,anio,idcentroreintegro) 
	VALUES(rplancobpersona.nrodoc,rplancobpersona.tipodoc,null,null,centro(),55,0.0,null,0.0,rplancobpersona.formapago_expendio,2219,null,null,null,1,rplancobpersona.idasocconv_expendio,aux.nroreintegro,aux.anio,aux.idcentroregional);
	
	INSERT INTO tempreintegromodificado(nroreintegro,anio,idcentroregional,tipoprestacion,importe,observacion,prestacion,cantidad) 
	VALUES (aux.nroreintegro,aux.anio,aux.idcentroregional,rplancobpersona.tipoprestacion,resposibleconsumo.pimportepractica,'Generado automaticamente usando el plan de coberturas',rplancobpersona.tipoprestacion,1);
	INSERT INTO tempitems (cantidad,importe,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idplancob,auditada,porcentaje,idpiezadental,idzonadental,idletradental,amuc,afiliado,sosunc, tipoprestacion,obsprestacion) 
	VALUES(1,resposibleconsumo.pimportepractica,rplancobpersona.idnomenclador,rplancobpersona.idcapitulo,rplancobpersona.idsubcapitulo,rplancobpersona.idpractica,rplancobpersona.idplancoberturas_expendio,null,null,'','','',resposibleconsumo.pimporteamuc,resposibleconsumo.pimporteafiliado,resposibleconsumo.pimportesosunc,rplancobpersona.tipoprestacion,'Generado automaticamente usando el plan de coberturas');
	
	SELECT INTO rreciboorden * FROM expendio_orden();
--KR 08-05-18 Comento ya que no se anula la orden
	-- INSERT INTO ordenestados (nroorden,centro, fechacambio,idordenestadotipos) 
      --             VALUES (rreciboorden.nroorden,rreciboorden.centro,CURRENT_TIMESTAMP,1);
         PERFORM expendio_cambiarestadoorden(rreciboorden.nroorden, rreciboorden.centro, 1);

	SELECT INTO rinforme * FROM informefacturacionexpendioreintegro WHERE nroreintegro = aux.nroreintegro
							AND anio = aux.anio 
							AND idcentroregional = aux.idcentroregional;
	IF FOUND THEN 
		PERFORM cambiarestadoinformefacturacion(rinforme.nroinforme,rinforme.idcentroinformefacturacion,9,' Escondido para facturar por sistema de emision de comprobante masivo');
	END IF;
        IF iftableexistsparasp('ttordenesgeneradas') THEN

		DELETE FROM ttordenesgeneradas;
        END IF;
	RAISE NOTICE 'se genero el reintegro (%)',concat(aux.nroreintegro,'-',aux.anio,'-',aux.idcentroregional);
	
/*
         
	 --actualizacion de estado de reintegro a liquidable  
	SELECT INTO aux * FROM reintegro where reintegro.idrecepcion = idrecepciont and reintegro.idcentrorecepcion = centro() and reintegro.anio=date_part('year', NOW());

      if (nullvalue(aux.rimporte)) then

      if (rplancobpersona.barra>=1 and rplancobpersona.barra<30) then

         SELECT INTO rbeneficiario * FROM benefsosunc  WHERE benefsosunc.nrodoc = nrodoct AND benefsosunc.tipodoc =    tipodoct;
         
       -- busco si la persona tiene  nro de cuenta ya insertado
         SELECT INTO rcuentas * FROM cuentas  WHERE rbeneficiario.nrodoc = cuentas.nrodoc AND rbeneficiario.tipodoc =    cuentas.tipodoc; 
          IF not  FOUND then    -- si no tiene insertada nro de cuenta 
                  SELECT INTO rcuentas * FROM cuentas  WHERE rbeneficiario.nrodoctitu = cuentas.nrodoc AND rbeneficiario.tipodoctitu =    cuentas.tipodoc;
                       IF   FOUND then
                            INSERT INTO cuentas(nrodoc,tipodoc,nrocuenta,tipocuenta,digitoverificador,nrobanco,nrosucursal)    VALUES 
                                (nrodoct,tipodoct,rcuentas.nrocuenta,rcuentas.tipocuenta,rcuentas.digitoverificador,rcuentas.nrobanco,rcuentas.nrosucursal);

 UPDATE reintegro SET nrocuenta = rcuentas.nrocuenta, tipocuenta=rcuentas.tipocuenta WHERE reintegro.idrecepcion = idrecepciont and reintegro.idcentrorecepcion = centro() and reintegro.anio=date_part('year', NOW());
                       end if;
           
           end if;
           
          end if;

         UPDATE reintegro SET rimporte = 1000 WHERE reintegro.idrecepcion = idrecepciont and reintegro.idcentrorecepcion = centro() and reintegro.anio=date_part('year', NOW());

        UPDATE reintegroprestacion SET importe = 1000 WHERE reintegroprestacion.nroreintegro = aux.nroreintegro and reintegroprestacion.idcentroregional = centro() and reintegroprestacion.tipoprestacion=27 and reintegroprestacion.anio=date_part('year', NOW());
 


      end if;

 
            UPDATE restados SET fechacambio = NOW() WHERE nroreintegro=aux.nroreintegro and tipoestadoreintegro=1 and idcentroregional=aux.idcentroregional and anio=date_part('year', NOW());

            INSERT INTO restados
                 (fechacambio,nroreintegro,tipoestadoreintegro,anio,observacion,idcentroregional)
                 VALUES(NOW(),aux.nroreintegro,2,date_part('year', NOW()),'Generados Automaticamente',aux.idcentroregional);

   */
	END IF;
   fetch cursorplanes into rplancobpersona;
   END LOOP;
CLOSE cursorplanes;

DROP TABLE esposibleelconsumo;
DROP TABLE temporden;
DROP TABLE tempreintegromodificado;
DROP TABLE tempitems;
 IF iftableexistsparasp('ttordenesgeneradas') THEN
     DROP TABLE ttordenesgeneradas;
 END IF;
return true;   

END;$function$
