CREATE OR REPLACE FUNCTION public.guardar_precarga_comprobante_compra(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE

--RECORD
  rfiltros RECORD;
  rrlfp  RECORD;
  rusuario  RECORD;
  reccentrocosto RECORD;
--CURSORES  
  curcentrocostos refcursor;

--VARIABLES
  respuesta VARCHAR;
  
   
BEGIN
 SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
 IF NOT FOUND THEN 
   rusuario.idusuario = 25;
 END IF;
 EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
 IF not (rfiltros.fechaemision > to_char( date_trunc('month',now())-'12month' ::interval-'1sec' ::interval, 'YYYY-MM-DD' ) 
                         and rfiltros.fechaemision < to_char( date_trunc('day',now())+'1day' ::interval, 'YYYY-MM-DD' )
                    )THEN
                  	-- La fecha de emision del comprobante NO PUEDE SER > a la fecha actual + 1 ni menor a 12 meses
      RAISE EXCEPTION 'FECHA EMISION INVALIDA';
 END IF;
 SELECT INTO rrlfp * FROM rlf_precarga WHERE idrlfprecarga= rfiltros.idrlfprecarga AND idcentrorlfprecarga = rfiltros.idcentrorlfprecarga;
 IF NOT FOUND THEN -- no existe la precarga
    INSERT INTO rlf_precarga(fechaemision,obs,rlfpiibbotrajuri,catgasto,numfactura,rlfpiibbrionegro,idtipocomprobante,netoiva105,netoiva21,montocentrocostofarmacia,montocentrocostoteatro,condcompra,retiva,netoiva27,percepciones,descuento,iva27,fecharecepcion,nogravado,recargo,iva21,fechavenc,retganancias,exento,monto,rlfpiibbneuquen,subtotal,iva105,idprestador,rlfp_movctacte,rlfp_idusuario) 
	VALUES (rfiltros.fechaemision,rfiltros.obs,rfiltros.rlfpiibbotrajuri::numeric,rfiltros.comboCatGto,rfiltros.numfactura::bigint,rfiltros.rlfpiibbrionegro::numeric,rfiltros.comboTipoComp::integer,rfiltros.netoiva105::numeric,rfiltros.netoiva21::numeric,rfiltros.montocentrocostoteatro::numeric,rfiltros.comboCondCompra::integer,rfiltros.retiva::numeric,rfiltros.netoiva27::numeric,rfiltros.percepciones::numeric,rfiltros.descuento::numeric,rfiltros.iva27::numeric,rfiltros.fecharecepcion,rfiltros.nogravado::numeric,rfiltros.recargo::numeric,rfiltros.iva21::numeric,rfiltros.fechavenc,rfiltros.retganancias::numeric,rfiltros.exento::numeric,rfiltros.monto::numeric,rfiltros.rlfpiibbneuquen::numeric,rfiltros.subtotal::numeric,rfiltros.iva105::numeric,rfiltros.comboCUIT,rfiltros.checkboxmvtoctacte,rusuario.idusuario);

    

    INSERT INTO rlf_precargaitemscentroscosto (idrlfprecarga, idcentrorlfprecarga,idcentrocosto,monto)  VALUES (currval('rlf_precarga_idrlfprecarga_seq'),centro(),rfiltros.montocentrocostofarmacia::numeric,rfiltros.monto::numeric);

    INSERT INTO rlf_precarga_estado(idrlfprecarga,idcentrorlfprecarga, rlfpedescripcion, rlfpeidusuario,tipoestadofactura)
    VALUES(currval('rlf_precarga_idrlfprecarga_seq'),centro(), concat('Precarga realizada el ', now(), '. SP guardar_precarga_comprobante_compra'), rusuario.idusuario, 12);

    
    respuesta = concat(currval('rlf_precarga_idrlfprecarga_seq'),'|', centro());
 ELSE -- el comprobante existe, lo modifico
    UPDATE  rlf_precarga SET fechaemision = rfiltros.fechaemision,
			     fechavenc =  rfiltros.fechavenc,
			     numfactura = rfiltros.numfactura, 
			     monto = rfiltros.monto::numeric,
			     idprestador = rfiltros.idprestador,
                             idtipocomprobante = rfiltros.idtipocomprobante::integer,
                             clase = rfiltros.clase ,
                             montosiniva = rfiltros.montosiniva::numeric,
                             descuento = rfiltros.descuento::numeric,
                             recargo = rfiltros.recargo::numeric,
                             exento = rfiltros.exento::numeric,
                             catgasto = rfiltros.catgasto,
                             condcompra =  rfiltros.condcompra::integer,
                             talonario = rfiltros.talonario::integer,
                             iva21 = rfiltros.iva21::numeric,
                             iva105 =  rfiltros.iva105::numeric,
                             iva27 = rfiltros.iva27::numeric,
                             letra = rfiltros.letra,
                             netoiva105 = rfiltros.netoiva105::numeric,
                             netoiva21 =  rfiltros.netoiva21::numeric,
                             netoiva27 =  rfiltros.netoiva27::numeric,
                             nogravado = rfiltros.nogravado::numeric,
                             numero = rfiltros.numero,
                             obs =  rfiltros.obs,
                             percepciones = rfiltros.percepciones::numeric,
                             puntodeventa =  rfiltros.puntodeventa,
                             retganancias = rfiltros.retganancias::numeric,
                             rlfpiibbneuquen = rfiltros.rlfpiibbneuquen::numeric,
                             rlfpiibbrionegro = rfiltros.rlfpiibbrionegro::numeric,
                             rlfpiibbotrajuri = rfiltros.rlfpiibbotrajuri::numeric,
                             retiva = rfiltros.retiva::numeric,
                             subtotal =  rfiltros.subtotal::numeric,
                             tipocambio = rfiltros.tipocambio::numeric,
                             rlfp_idusuario = rusuario.idusuario,
                             montocentrocostoos = rfiltros.montocentrocostoos::numeric,
                             montocentrocostofarmacia = rfiltros.montocentrocostofarmacia::numeric,
                             montocentrocostoteatro = rfiltros.montocentrocostoteatro::numeric,
                             rlfp_movctacte = rfiltros.checkboxmvtoctacte
    WHERE idrlfprecarga= rfiltros.idrlfprecarga AND idcentrorlfprecarga = rfiltros.idcentrorlfprecarga;
    respuesta = concat(rfiltros.idrlfprecarga,'|', rfiltros.idcentrorlfprecarga); 
 END IF;

    OPEN curcentrocostos FOR SELECT * FROM tempprecarga;
    FETCH curcentrocostos INTO reccentrocosto;
    WHILE  found LOOP
		   -- Inserto los centros de costos del comprobante
			INSERT INTO rlf_precargaitemscentroscosto(idrlfprecarga,idcentrorlfprecarga,idcentrocosto,monto,idactividad)
			VALUES(currval('rlf_precarga_idrlfprecarga_seq'),centro(),reccentrocosto.idcentrocosto,reccentrocosto.monto,reccentrocosto.idactividad);
    FETCH curcentrocostos INTO reccentrocosto;
    END LOOP;
    CLOSE curcentrocostos;

return respuesta;
END;
$function$
