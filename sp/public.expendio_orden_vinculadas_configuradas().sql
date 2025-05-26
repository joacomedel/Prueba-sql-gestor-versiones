CREATE OR REPLACE FUNCTION public.expendio_orden_vinculadas_configuradas()
 RETURNS type_expendio_orden
 LANGUAGE plpgsql
AS $function$DECLARE
--INTEGER
resp bigint;
respbolean boolean;
rrecibo type_expendio_orden;
unitemorigen RECORD;
unaordenorigen RECORD;
unreciboorigen RECORD;
unaconfiguracion RECORD;
practicasconfig refcursor;
vparam VARCHAR;

BEGIN

--Hay que recuperar la informacion de la orden que origina las otras ordenes. 
IF  iftableexists('ttordenesgeneradas')  THEN
	SELECT INTO unreciboorigen idrecibo as orvidreciboorigen , nroorden as orvnroordenorigen, centro as orvcentroorigen,*
              FROM ttordenesgeneradas NATURAL JOIN ordenrecibo NATURAL JOIN consumo NATURAL JOIN orden NATURAL JOIN itemvalorizada LIMIT 1;
--	SELECT INTO unaordenorigen *  FROM temporden;
--	SELECT INTO unitemorigen * FROM tempitems;
END IF;
--Verifico si hay que emitir alguna orden vinculada a las practicas que se van a expender.
OPEN practicasconfig FOR  SELECT peocodigopractica,peoagrupador,count(*) as cantidaditems
								FROM practica_emitirorden 
								NATURAL JOIN (
									SELECT concat(idnomenclador,'.',idcapitulo,'.',idsubcapitulo,'.',idpractica) as peocodigopractica, * 
									FROM tempitems ) as itemsemitidos
							WHERE nullvalue(peofechaanulacion) 
									AND (idplancob = peoidplancobertura OR peoidplancobertura = '**' )
							GROUP BY peocodigopractica,peoagrupador;
FETCH practicasconfig INTO unaconfiguracion;
WHILE  found LOOP

--Cada Agrupador determina una Orden que debe ser Emitida
	DELETE FROM temporden;
	DELETE FROM tempitems;
	IF  iftableexists('ttordenesgeneradas')  THEN
		DELETE FROM ttordenesgeneradas;
	END IF;

-- Expendo la Orden relacionada con la configuracion
--rparam.peocodigopractica,idplancoberturas,idasocconv,nrodoc,tipodoc
--SP para llamar generar_orden_consumoafiliado_config('{peocodigopractica,idplancoberturas,idasocconv,nrodoc,tipodoc}')
 vparam = concat('{peocodigopractica =',unaconfiguracion.peocodigopractica,',idplancoberturas=',unreciboorigen.idplancovertura,',idasocconv = ',unreciboorigen.idasocconv,',nrodoc=',unreciboorigen.nrodoc,',tipodoc=',unreciboorigen.tipodoc,'}');
PERFORM generar_orden_consumoafiliado_config(vparam);
-- Vinsulamos las ordenes
IF  iftableexists('ttordenesgeneradas_2')  THEN
INSERT INTO ordenrecibo_vinculada(orvidreciboorigen, orvcentroorigen, orvnroordenorigen, orvidrecibovinculado,orvnroordenvinculado,orvcentrovinculado)
  ( 
	 SELECT unreciboorigen.orvidreciboorigen,unreciboorigen.orvcentroorigen,unreciboorigen.orvnroordenorigen,idrecibo, nroorden,centro 
     FROM ttordenesgeneradas_2
	 NATURAL JOIN ordenrecibo	 );
END IF;


FETCH practicasconfig INTO unaconfiguracion;
END LOOP;
CLOSE practicasconfig;

-- Devolvemos el recibo Original, desde ese se pueden obtener los recibos vinculados generados
SELECT INTO rrecibo idrecibo,nroorden,centro,ctdescripcion
     FROM recibo
     NATURAL JOIN ordenrecibo
     NATURAL JOIN orden
     JOIN comprobantestipos ON (orden.tipo = comprobantestipos.idcomprobantetipos)
     WHERE centro = unreciboorigen.orvcentroorigen and  idrecibo=unreciboorigen.orvidreciboorigen  ;

return rrecibo;
END;
$function$
