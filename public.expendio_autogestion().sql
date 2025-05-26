CREATE OR REPLACE FUNCTION public.expendio_autogestion()
 RETURNS SETOF type_expendio_orden
 LANGUAGE plpgsql
AS $function$DECLARE
resp bigint;
respbolean boolean;
rrecibo type_expendio_orden;

rrecibovuelve type_expendio_orden;

    respuesta boolean;
    
--RECORD 
  rdatoseag RECORD;
  rdatoseagantes RECORD;
  seconsume RECORD;
  rlasordenes RECORD;
--CURSORES
  clasordenes refcursor; 
BEGIN

SELECT INTO rdatoseag * FROM temp_expendioag;
 
IF (rdatoseag.accion ILIKE '%anular%') THEN
          
    IF (not nullvalue(rdatoseag.idrecibo)) THEN
    OPEN clasordenes FOR  SELECT * FROM ordenrecibo WHERE idrecibo = rdatoseag.idrecibo AND centro=rdatoseag.centro;
    FETCH clasordenes  INTO rlasordenes;
      WHILE found LOOP
			   
         INSERT INTO ordenestados (nroorden,centro, fechacambio,idordenestadotipos) 
                   VALUES (rlasordenes.nroorden,rlasordenes.centro,CURRENT_TIMESTAMP,1);
         PERFORM expendio_cambiarestadoorden (rlasordenes.nroorden, rlasordenes.centro, 2);
	    
       -- PERFORM asentarconsumoctactev2(rlasordenes.idrecibo,rlasordenes.centro,rlasordenes.nroorden);
      FETCH clasordenes  INTO rlasordenes;
   
      END LOOP;
    CLOSE clasordenes;
    SELECT INTO rrecibo * FROM ordenrecibo WHERE idrecibo = rdatoseag.idrecibo AND centro=rdatoseag.centro limit 1;
   ELSE 
 OPEN clasordenes FOR  SELECT * FROM ordenrecibo WHERE nroorden = rdatoseag.nroorden AND centro=rdatoseag.centro;
     FETCH clasordenes  INTO rlasordenes;
      WHILE found LOOP
			   
         INSERT INTO ordenestados (nroorden,centro, fechacambio,idordenestadotipos) 
                   VALUES (rlasordenes.nroorden,rlasordenes.centro,CURRENT_TIMESTAMP,1);
         PERFORM expendio_cambiarestadoorden (rlasordenes.nroorden, rlasordenes.centro, 2);
	    
       -- PERFORM asentarconsumoctactev2(rlasordenes.idrecibo,rlasordenes.centro,rlasordenes.nroorden);
      FETCH clasordenes  INTO rlasordenes;
   
      END LOOP;
    CLOSE clasordenes;
    SELECT INTO rrecibo * FROM ordenrecibo WHERE nroorden = rdatoseag.nroorden AND centro=rdatoseag.centro limit 1;
   END IF;
ELSE 
   
  IF (rdatoseag.accion ILIKE '%consulta%') THEN
       UPDATE   temp_expendioag SET tipo = 53,idnomenclador='12', idcapitulo='42', idsubcapitulo='01',idpractica='01';        

        
    ELSE
        UPDATE   temp_expendioag SET tipo=37,idnomenclador='98', idcapitulo='01', idsubcapitulo='01',idpractica='02'; 
    END IF;
 
SELECT INTO rdatoseag * FROM temp_expendioag;

-- RAISE EXCEPTION 'rdatoseag  % %',rdatoseag.idnomenclador,rdatoseag.tipo;
  

  -- IF NOT  iftableexistsparasp('temporden') THEN

	CREATE TEMP TABLE temporden(nrodoc varchar(8),
	tipodoc int  NOT NULL,
 	numorden bigint , 
	ctroorden integer,
	centro int4 NOT NULL,
	recibo boolean,
 	tipo int8,
        amuc float ,
 	afiliado float ,
 	sosunc float,
        enctacte boolean,
	idprestador INTEGER,
	ordenreemitida INTEGER,
	centroreemitida INTEGER,
	nromatricula INTEGER,
 	cantordenes INTEGER, 
 	idasocconv BIGINT,
 	nroreintegro BIGINT, 
 	anio INTEGER,
        autogestion BOOLEAN,
 	idcentroreintegro INTEGER,
    formapago INTEGER
	) WITHOUT OIDS;

 --  END IF;

    CREATE TEMP TABLE esposibleelconsumo (idpractica character varying,   
    idplancobertura character varying,    
    idnomenclador character varying,    
    auditoria boolean,    
    cobertura integer,  
    idcapitulo character varying,     
    idsubcapitulo character varying,     
    idplancoberturas bigint,    
    ppccantpractica integer,  
    ppcperiodo character varying,     
    ppccantperiodos integer,     
    ppclongperiodo integer,     
    ppcprioridad integer,     
    idconfiguracion bigint,    
    serepite boolean,  
    ppcperiodoinicial integer,    
    ppcperiodofinal integer,    
    rcantidadconsumida integer,    
    rcantidadrestante integer,    
    nivel integer,    
    fechadesde date,    
    fechahasta date,  
    pimportepractica double precision,    
    pimporteamuc double precision,    
    pimporteafiliado double precision,    
    pimportesosunc double precision,    
    coberturaamuc double precision,  
    nrocuentac character varying,    
    idesposibleelconsumo integer,
    coberturasosunc double precision,
    esreintegro boolean);

  
     PERFORM expendio_verificar_consumo(rdatoseag.idnomenclador,rdatoseag.idcapitulo,rdatoseag.idsubcapitulo,rdatoseag.idpractica
                 ,rdatoseag.idplancobertura,  rdatoseag.nrodoc,rdatoseag.tipodoc,rdatoseag.idasocconv);
    /*             
               SELECT into respuesta    expendio_verificar_consumo(rdatoseag.idnomenclador,rdatoseag.idcapitulo,rdatoseag.idsubcapitulo,rdatoseag.idpractica
                 ,rdatoseag.idplancobertura,  rdatoseag.nrodoc,rdatoseag.tipodoc,rdatoseag.idasocconv);
      */           
               
                 

--02-07-14 no quiero que tome la configuracion global PUES esta mal configurada en el modulo asistencial
/*           SELECT INTO seconsume * FROM esposibleelconsumo   as e
         	WHERE e.rcantidadrestante > 0  AND e.fechadesde <= current_date  and not auditoria
                 AND idsubcapitulo <>'**'
           	AND e.fechahasta >= current_date  ORDER BY nivel DESC,ppcprioridad;

*/

  SELECT INTO seconsume * FROM esposibleelconsumo   as e
  	WHERE e.rcantidadrestante > 0  AND e.fechadesde <= current_date   AND idsubcapitulo <>'**'
           	AND e.fechahasta >= current_date  ORDER BY nivel DESC,ppcprioridad;


    
IF FOUND THEN 

    INSERT INTO temporden(nrodoc,tipodoc,numorden,ctroorden,centro,tipo,amuc,afiliado,
			sosunc,enctacte,idprestador,ordenreemitida,centroreemitida,
			nromatricula,cantordenes,idasocconv,nroreintegro,anio,idcentroreintegro,autogestion) 
	VALUES(rdatoseag.nrodoc,rdatoseag.tipodoc,null,null,centro(),rdatoseag.tipo,seconsume.pimporteamuc,seconsume.pimporteafiliado,seconsume.pimportesosunc,
		false,null,null,null,null,rdatoseag.cantidad,rdatoseag.idasocconv,null,null,null,true);

  --IF NOT  iftableexistsparasp('tempitems') THEN

	CREATE TEMP TABLE tempitems(cantidad int4 NOT NULL,importe float NOT NULL,idnomenclador varchar,idcapitulo varchar,idsubcapitulo varchar,idpractica varchar,idplancob varchar,auditada boolean,porcentaje integer,idpiezadental varchar,idzonadental varchar,idletradental varchar,amuc FLOAT4 ,afiliado FLOAT4,sosunc FLOAT4) WITHOUT OIDS;
  END IF;

        INSERT INTO tempitems (cantidad,importe,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idplancob,auditada,porcentaje,idpiezadental,idzonadental,idletradental,amuc,afiliado,sosunc) 
        VALUES(1,seconsume.pimportepractica,rdatoseag.idnomenclador,rdatoseag.idcapitulo,rdatoseag.idsubcapitulo,rdatoseag.idpractica,rdatoseag.idplancobertura,null,seconsume.cobertura,'','','',seconsume.pimporteamuc,seconsume.pimporteafiliado,seconsume.pimportesosunc);

	

  SELECT INTO rrecibo * FROM expendio_orden();
 --RAISE EXCEPTION 'rrecibo  % %',rrecibo.idrecibo,rrecibo.centro;
  INSERT INTO reciboautogestionfacturaventa (idrecibo,    centro) VALUES(rrecibo.idrecibo, rrecibo.centro);

  PERFORM expendio_cambiarestadoorden (nroorden, centro, 1)
           FROM ordenrecibo WHERE centro = centro() and  idrecibo=rrecibo.idrecibo ;
	  END IF; --del if que verifica no excede el consumo permitido



---END IF; --end if del expender 



FOR rrecibovuelve IN

     SELECT  idrecibo,nroorden,centro,ctdescripcion
     FROM recibo NATURAL JOIN ordenrecibo
     NATURAL JOIN orden
     JOIN comprobantestipos ON (orden.tipo = comprobantestipos.idcomprobantetipos)
     WHERE centro = centro() and  idrecibo=rrecibo.idrecibo  

 LOOP



return next rrecibovuelve;
     
end loop;



 end;

$function$
