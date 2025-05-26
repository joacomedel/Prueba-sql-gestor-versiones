CREATE OR REPLACE FUNCTION public.alta_modifica_auditoria_vincular_orden()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES
  vseaudito BOOLEAN;
  respuesta VARCHAR;
  vusuario INTEGER; 
  vtipoprestacion INTEGER; 
  verifica BOOLEAN;
  elidfichamedica BIGINT;
  elidfichamedicaitem BIGINT; 
  elidcentroidfichamedica INTEGER;
  elidnomenclador VARCHAR;
  elidcapitulo VARCHAR;
  elidsubcapitulo VARCHAR;
  elidpractica VARCHAR;
  elidfichamedicaitempendiente BIGINT;
  elidfichamedicaitempendientecentro INTEGER;

--RECORD
  rfichamedicaitem RECORD;
  rverifica RECORD; 
  ritem RECORD;
  rorden RECORD;

--CURSOR
  cursoritem refcursor;
  cursororden refcursor;


BEGIN

-- EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

 vusuario = sys_dar_usuarioactual();


--KR 03-01-20 COmente, el iierror lo saca del combo 
--MaLaPi 07-04-2020 Lo descomento para que se use en la auditoria masiva

UPDATE temp_alta_modifica_ficha_medica SET iierror = 'La practica fue autorizada.'
WHERE (operacion ilike 'aprobar' OR cobertura > 0)
AND trim(iierror) = trim('La practica requiere autorizacion.');

UPDATE temp_alta_modifica_ficha_medica SET iierror = 'La practica NO fue autorizada.'
WHERE (operacion ilike 'rechazar' OR cobertura = 0)
AND trim(iierror) = trim('La practica requiere autorizacion.');

vseaudito = false;

 OPEN cursoritem FOR SELECT * from temp_alta_modifica_ficha_medica;
 FETCH cursoritem INTO ritem;
 WHILE  found LOOP
     
     SELECT INTO elidnomenclador split_part(ritem.lapractica, '.',1);
     SELECT INTO elidcapitulo split_part(ritem.lapractica, '.',2);
     SELECT INTO elidsubcapitulo split_part(ritem.lapractica, '.',3);
     SELECT INTO elidpractica split_part(ritem.lapractica, '.',4);

     elidfichamedicaitempendiente = ritem.idfichamedicaitempendiente;
     elidfichamedicaitempendientecentro = ritem.idcentrofichamedicaitempendiente;

     IF ritem.iditemestadotipo = 1 THEN -- MaLapi 29-10-2019 Audito solo las practicas que lo estan esperando, el resto las dejo como estan
    
      vseaudito = true;

     IF NOT nullvalue(ritem.idfichamedicaitem) THEN   -- NO es una nueva auditoria
        
        UPDATE fichamedicaitem SET  fmifechaauditoria = now()
            ,idusuario = vusuario
            ,fmicantidad = ritem.fmicantidad
            --,fmidescripcion = elem.fmidescripcion
            
        WHERE idfichamedicaitem = ritem.idfichamedicaitem  AND idcentrofichamedicaitem = ritem.idcentrofichamedicaitem;           
    
        UPDATE fichamedicaitemonline SET fmiocantidad = ritem.fmicantidad, fmiocobertura = ritem.cobertura/100
            WHERE idfichamedicaitem = ritem.idfichamedicaitem  AND idcentrofichamedicaitem = ritem.idcentrofichamedicaitem;	

        SELECT INTO verifica * FROM fichamedicaemision WHERE idfichamedicaitem = ritem.idfichamedicaitem  AND idcentrofichamedicaitem = ritem.idcentrofichamedicaitem;
        IF NOT FOUND THEN

            SELECT INTO vtipoprestacion  tipoprestacion.tipoprestacion FROM practica JOIN mapeoctascontablesexpendioreintegro as mccer  
			ON (nrocuentacexpendio=practica.nrocuentac) JOIN tipoprestacion ON (nrocuentacreintegro=tipoprestacion.nrocuentac)
			WHERE practica.idnomenclador = elidnomenclador AND practica.idcapitulo=elidcapitulo AND practica.idsubcapitulo=elidsubcapitulo AND practica.idpractica=elidpractica;
						
           INSERT INTO fichamedicaemision(nrodoc,tipodoc,fmepfecha,idauditoriatipo,idfichamedicaitem,idcentrofichamedicaitem,fmepcantidad,idnomenclador,idcapitulo,idsubcapitulo,idpractica,tipoprestacion,fmefechavto)
       VALUES(ritem.nrodoc,ritem.tipodoc,now(),ritem.idauditoriatipo,ritem.idfichamedicaitem,ritem.idcentrofichamedicaitem,ritem.fmicantidad,elidnomenclador
                ,elidcapitulo,elidsubcapitulo,elidpractica,vtipoprestacion,(date_trunc('YEAR', CURRENT_DATE) + INTERVAL '1 YEAR - 1 day')::DATE);
           
         END IF;
   
    UPDATE fichamedicaemisionestado SET fmeefechafin = now() WHERE idfichamedicaitem= ritem.idfichamedicaitem AND idcentrofichamedicaitem = ritem.idcentrofichamedicaitem AND NULLVALUE(fmeefechafin);
    INSERT INTO fichamedicaemisionestado(idfichamedicaitem,idcentrofichamedicaitem,idfichamedicaemisionestadotipo,fmeedescripcion,idauditoriatipo)
    VALUES (ritem.idfichamedicaitem,ritem.idcentrofichamedicaitem,1,'Generado desde Auditoria Medica  SP alta_modifica_auditoria_vincular_orden',ritem.idauditoriatipo);
        
    
  --  UPDATE iteminformacion SET iierror= (CASE WHEN (ritem.fmicantidad<=0) THEN 'La practica no fue autorizada. ' ELSE 'La practica fue autorizada. ' END)
  --   WHERE iteminformacion.iditem=ritem.iditem AND iteminformacion.centro=ritem.centro;

 ELSE --NO existe la auditoria 

    INSERT INTO fichamedicaitem (fmifechaauditoria,idprestador,idusuario,fmiporreintegro,fmicantidad,fmidescripcion
            ,idfichamedica,idcentrofichamedica,idnomenclador,idcapitulo,idsubcapitulo,idpractica,idcentrofichamedicaitem)  
    VALUES(ritem.fmifechaauditoria, ritem.idprestador, vusuario, false, ritem.fmicantidad, ritem.iierror, ritem.idfichamedica, ritem.idcentrofichamedica,elidnomenclador, elidcapitulo,elidsubcapitulo, elidpractica,centro());
    elidfichamedicaitem = currval('public.fichamedicaitem_idfichamedicaitem_seq');

    INSERT INTO fichamedicaitemestado(idfichamedicaitem,idcentrofichamedicaitem,idfichamedicaemisionestadotipo,fmiedescripcion,fmieusuario)
    VALUES (elidfichamedicaitem,centro(),3,'Generado desde alta_modifica_auditoria_vincular_orden',vusuario);

 
    INSERT INTO fichamedicaitemonline (idnomenclador,idcapitulo,idfichamedicaitem,idcentrofichamedicaitem,idsubcapitulo,idpractica,fmiocantidad,fmiocobertura)
values 
(elidnomenclador, elidcapitulo,elidfichamedicaitem,centro(),elidsubcapitulo,elidpractica,ritem.fmicantidad, ritem.cobertura/100);
       

    INSERT INTO fichamedicaitememisiones (idfichamedicaitem,idcentrofichamedicaitem,nroorden,centro)
    VALUES (elidfichamedicaitem,centro(),ritem.nroorden,ritem.centro);

--    UPDATE iteminformacion SET iierror= (CASE WHEN (ritem.fmicantidad<=0) THEN 'La practica no fue autorizada. ' ELSE 'La practica fue autorizada. ' END)
--     WHERE iteminformacion.iditem=ritem.iditem AND iteminformacion.centro=ritem.centro;

 END IF; 
 END IF;  -- Solo se auditan las practicas con iditemestadotipo = 1

FETCH cursoritem INTO ritem;
END LOOP;
CLOSE cursoritem;
  IF vseaudito THEN 
    --se modifican o generan los valores en la orden segun la cobertura auditada. 
      PERFORM expendio_ordenauditada();
  END IF;

--KR 16-04-20 Modifico para que cambie el pendiente de fichamedicaitempendienteestado si no queda ningun item pendiente por auditar
 OPEN cursororden FOR SELECT nroorden, centro from temp_alta_modifica_ficha_medica GROUP BY nroorden, centro;
 FETCH cursororden INTO rorden;
 WHILE  found LOOP
   SELECT INTO rverifica *
   FROM fichamedicaitempendiente 
   JOIN ordvalorizada ON (nroreintegro=nroorden AND idcentroregional=centro)  NATURAL JOIN itemvalorizada NATURAL JOIN item 
   NATURAL JOIN iteminformacion NATURAL JOIN itemestadotipo LEFT JOIN prestador ON (nromatricula = idprestador) 
   JOIN plancobertura pc ON idplancovertura= pc.idplancoberturas   
   WHERE   nroreintegro= rorden.nroorden  AND idcentroregional = rorden.centro  AND iditemestadotipo = 1 
   LIMIT 1;
   IF NOT FOUND THEN
--MaLaPi 30-10-2019 Solo cambio el estado de la orden, si no queda ningun item por auditar
     UPDATE fichamedicaitempendienteestado SET fmipfechafin = now() WHERE idfichamedicaitempendiente = elidfichamedicaitempendiente AND idcentrofichamedicaitempendiente = elidfichamedicaitempendientecentro AND nullvalue(fmipfechafin);
     INSERT INTO fichamedicaitempendienteestado(idfichamedicaitempendiente,idcentrofichamedicaitempendiente,idfichamedicaemisionestadotipo,fmipidusuario) 
		VALUES(elidfichamedicaitempendiente,elidfichamedicaitempendientecentro,3,vusuario);
  END IF;
 FETCH cursororden INTO rorden;
 END LOOP;
 CLOSE cursororden;
return respuesta; 
END;
$function$
