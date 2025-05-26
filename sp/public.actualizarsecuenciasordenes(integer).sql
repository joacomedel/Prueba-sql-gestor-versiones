CREATE OR REPLACE FUNCTION public.actualizarsecuenciasordenes(integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$ 
DECLARE
       resultado  boolean;
	idcentro integer;
	valorconsulta integer;
	valorconsulta2 integer;
	valorseq integer;
      valorseqrec bigint;
valorseqrec2 bigint;
valor bigint;
	

BEGIN

     --resultado = 'true';
      --reviso los valores orden
	SELECT into valorconsulta MAX(nroorden) FROM orden where centro=$1;
	--SELECT into valorseq last_value +1 from orden_nroorden_seq;
	SELECT into valor setval ('orden_nroorden_seq', valorconsulta+1);
	

	--reviso los valores consumo
        SELECT into valorconsulta MAX(idconsumo) FROM consumo where centro=$1;
	--SELECT into valorseq last_value +1 from  consumo consumo_idconsumo_seq;
	SELECT  into valor setval ('consumo_idconsumo_seq', valorconsulta+1);
	

	--reviso los valores recetarioestados
        SELECT into valorseqrec MAX(idrecetarioestado) FROM recetarioestados where centro=$1;
	--SELECT into valorseq last_value +1 from recetarioestados_idrecetarioestado_seq;
	SELECT  into valorseqrec2 setval ('recetarioestados_idrecetarioestado_seq', valorseqrec+1);
	

       --reviso los valores item
        SELECT into valorconsulta MAX(iditem) FROM item where centro=$1;
	--SELECT into valorseq last_value +1 from item_iditem_seq;
	SELECT  into valor setval ('item_iditem_seq', valorconsulta+1);
	
	
	

	--reviso los valores recibo
        SELECT into valorconsulta MAX(idrecibo) FROM recibo where recibo.idrecibo<1000000000 and centro=$1;
        SELECT into valorconsulta2 MAX(idrecibo) FROM recibo where centro=$1;
        update  secuencias set idrecibo=valorconsulta+1,idrecibocaja=valorconsulta2+1;	

       
	--reviso los valores cuentacorrientedeuda
        select into valorconsulta max(iddeuda) from cuentacorrientedeuda where idcentrodeuda=$1;
     --   SELECT into valorseq last_value +1 from cuentacorrientedeuda_iddeuda_seq;
	SELECT  into valor setval ('cuentacorrientedeuda_iddeuda_seq', valorconsulta+1);


--reviso los valores reintegro
SELECT into valorconsulta MAX(nroreintegro) from reintegro where idcentroregional=$1;
SELECT  into valor setval ('reintegro_nroreintegro_seq', valorconsulta+1);
	

--reviso los valores recepcion
SELECT into valorconsulta MAX(idrecepcion) from recepcion where idcentroregional=$1;
SELECT  into valor setval ('recepcion_idrecepcion_seq', valorconsulta+1);



--reviso los valores comprobante
SELECT into valorconsulta MAX(idcomprobante) from comprobante where idcentroregional=$1;
SELECT  into valor setval ('comprobante_idcomprobante_seq', valorconsulta+1);



--aca esta la secuencia involucrada en ordenes de odonto o psicologia....ver si hay mas..
select  into valorconsulta  max(idfichamedicaitememisiones) from fichamedicaitememisiones
 where   idcentrofichamedicaitememisiones=$1;
SELECT  into valor setval ('fichamedicaitememisiones_idfichamedicaitememisiones_seq',valorconsulta+1);




--aca estan las secuencias involucradas en turismo
select into valorconsulta max(idpago) from cuentacorrientepagos where idcentropago=$1;
SELECT  into valor setval ('cuentacorrientepagos_idpago_seq',valorconsulta+1);


 select into valorconsulta max(idpagos) from pagos where centro=$1;
 SELECT  into valor setval ('pagos_idpagos_seq',valorconsulta+1);

 
 select  into valorconsulta max(idpagoscuentacorriente) from pagoscuentacorriente where idcentroregional=$1;
SELECT  into valor setval ('pagoscuentacorriente_idpagoscuentacorriente_seq',valorconsulta+1);




 select   into valorconsulta max(idrecibocupon) from recibocupon where idcentrorecibocupon=$1;
SELECT  into valor setval ('recibocupon_idrecibocupon_seq',valorconsulta+1);


select    into valorconsulta max(nroinforme) from informefacturacion where idcentroinformefacturacion=$1;
SELECT  into valor setval ('informefacturacion_nroinforme_seq',valorconsulta+1);



select    into valorconsulta max(idinformefacturacionitem) from informefacturacionitem where idcentroinformefacturacionitem=$1;
SELECT  into valor setval ('informefacturacionitem_nroitem_seq',valorconsulta+1);


select     into valorconsulta max(idinformefacturacionestado) from informefacturacionestado 
where idcentroinformefacturacion=$1;
SELECT  into valor setval ('informefacturacionestado_idinformefacturacionestado_seq',valorconsulta+1);

select     into valorconsulta max(idprestamocuotas) from prestamocuotas where idcentroprestamocuota=$1;
SELECT  into valor setval ('prestamocuotas_idprestamocuotas_seq',valorconsulta+1);

 select     into valorconsulta max(idprestamo) from prestamo where idcentroprestamo=$1;
SELECT  into valor setval ('prestamo_idprestamo_seq',valorconsulta+1);


select     into valorconsulta max(idconsumoturismovalores) from consumoturismovalores where idcentroconsumoturismo=$1;
SELECT  into valor setval ('consumoturismovalores_idconsumoturismovalores_seq',valorconsulta+1);


select     into valorconsulta max(idconsumoturismo) from consumoturismo where idcentroconsumoturismo=$1;
SELECT  into valor setval ('consumoturismo_idconsumoturismo_seq',valorconsulta+1);




select     into valorconsulta max(idconsumoturismoestado) from consumoturismoestado where idcentroconsumoturismoestado=$1;
SELECT  into valor setval ('consumoturismoestado_idconsumoturismoestado_seq',valorconsulta+1);




 select     into valorconsulta max(idrecibocupon) from recibocupon where idcentrorecibocupon=$1;
 SELECT  into valor setval ('recibocupon_idrecibocupon_seq',valorconsulta+1);

select into valorconsulta  max(idpersonatoken) from persona_token where idcentropersonatoken=$1;
 SELECT  into valor setval ('persona_token_idpersonatoken_seq',valorconsulta+1);

select into valorconsulta  max(idfichamedicainfo)  from fichamedicainfo where idcentrofichamedicainfo=$1;
SELECT  into valor setval ('fichamedicainfo_idfichamedicainfo_seq',valorconsulta+1);

select into valorconsulta   max(idfichamedica) from fichamedica  where idcentrofichamedica=$1;
SELECT  into valor setval('fichamedica_idfichamedica_seq',valorconsulta+1); 


 select into valorconsulta max(idasientogenerico) from asientogenerico where idcentroasientogenerico=$1;
SELECT into valor setval('asientogenerico_idasientocontable_seq',valorconsulta+1);

select into valorconsulta max(idasientogenericoitem) from asientogenericoitem where idcentroasientogenericoitem=$1;
SELECT into valor  setval('asientogenericoitem_idasientocontableitem_seq',valorconsulta+1);

select into valorconsulta  max(idasientogenericoestado ) from asientogenericoestado where idcentroasientogenericoestado=$1;

SELECT  into valor  setval('asientogenericoestado_idasientocontableestado_seq',valorconsulta+1); 

 select into valorconsulta   max(idcatalogocomprobante) from catalogocomprobante where idcentrocatalogocomprobante=$1;

SELECT into valor   setval('catalogocomprobante_idcatalogocomprobante_seq',valorconsulta+1); 

select into valorconsulta max(idfichamedicaitempendiente) from fichamedicaitempendiente where idcentrofichamedicaitempendiente=$1;
 

SELECT into valor    setval('fichamedicaitempendiente_idfichamedicaitempendiente_seq',valorconsulta+1); 

select into valorconsulta max(idordenventa) from far_ordenventa where idcentroordenventa=$1; 

SELECT into valor    setval('far_ordenventa_idordenventa_seq',valorconsulta+1); 
select into valorconsulta max(idordenventaestado) from far_ordenventaestado where idcentroordenventaestado=$1; 

SELECT into valor    setval('far_ordenventaestado_idordenventaestado_seq',valorconsulta+1); 

select into valorconsulta max(idordenventaitem) from far_ordenventaitem where idcentroordenventaitem=$1; 

SELECT into valor    setval('far_ordenventaitem_idordenventaitem_seq',valorconsulta+1); 
select into valorconsulta max(idordenventaitemaestado) from far_ordenventaitemestado where idcentroordenventaitemestado=$1; 

SELECT into valor    setval('far_ordenventaitemestado_idordenventaitemaestado_seq',valorconsulta+1); 


select into valorconsulta max(idordenventaitemimportesaestado) from far_ordenventaitemimportesestado where idcentroordenventaitemimportesestado=$1; 

SELECT into valor    setval('far_ordenventaitemimportesest_idordenventaitemimportesaesta_seq',valorconsulta+1); 


RETURN 'true';
END;
$function$
