CREATE OR REPLACE FUNCTION public.mesaentrada_aprobarprecarga(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* Se ingresan / modifica / elimina los datos de una recepción */

DECLARE
--VARIABLES
elnumeroregistro VARCHAR;
--RECORD
rfiltros RECORD;
rcatgasto RECORD;
ractividad RECORD;  
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
IF NOT iftableexists('temprecepcion') THEN
   CREATE TEMP TABLE temprecepcion ( paraauditoria BOOLEAN,       
                   movctacte BOOLEAN DEFAULT false,        
                   idrecepcion INTEGER,       
                   fechavenc DATE,        
                   numfactura BIGINT,       
                   monto DOUBLE PRECISION,       
                   numeroregistro BIGINT,       
                   idprestador BIGINT,       
                   idlocalidad INTEGER,       
                   idtipocomprobante INTEGER,       
                   idtiporecepcion INTEGER DEFAULT 6,       
                   idcentroregional INTEGER DEFAULT centro(),       
                   idcentroregionalresumen INTEGER,       
                   idrecepcionresumen INTEGER,       
                   anio INTEGER DEFAULT date_part('year'::text, ('now'::text)::date),       
                   clase VARCHAR(1),       
                   montosiniva DOUBLE PRECISION,       
                   descuento DOUBLE PRECISION,       
                   recargo DOUBLE PRECISION,       
                   exento DOUBLE PRECISION,       
                   fechaemision DATE,       
                   fechaimputacion DATE,       
                   catgasto INTEGER,       
                   condcompra INTEGER,       
                   talonario INTEGER,       
                   iva21 DOUBLE PRECISION,       
                   iva105 DOUBLE PRECISION,       
                   iva27 DOUBLE PRECISION,       
                   letra CHAR(1),       
                   netoiva105 DOUBLE PRECISION,       
                   netoiva21 DOUBLE PRECISION,       
                   netoiva27 DOUBLE PRECISION,       
                   nogravado DOUBLE PRECISION,       
                   numero VARCHAR(8),       
                   obs VARCHAR(255),       
                   percepciones DOUBLE PRECISION,       
                   puntodeventa VARCHAR(5),       
                   retganancias DOUBLE PRECISION,       
                   retiibb DOUBLE PRECISION,       
                   retiva DOUBLE PRECISION,       
                   subtotal DOUBLE PRECISION,       
                   tipocambio DOUBLE PRECISION,       
                   tipofactura VARCHAR,       
                   fecharecepcion DATE,   
                   accion VARCHAR,    
                   idjurisdiccion INTEGER ,   
                   idactividad INTEGER,    
                   rlfpiibbneuquen DOUBLE PRECISION,    
                   rlfpiibbrionegro DOUBLE PRECISION,    
                   rlfpiibbotrajuri DOUBLE PRECISION ,
                   rlfdescuento21    DOUBLE PRECISION,
                   rlfrecargo21   DOUBLE PRECISION,
                   rlfivarecargo21  DOUBLE PRECISION,
                   idpresupuesto BIGINT, 
                   idcentropresupuesto INTEGER,
                   rlfdescuento27 DOUBLE PRECISION,
                   rlfrecargo27 DOUBLE PRECISION,
                   rlfivadescuento27 DOUBLE PRECISION,
                   rlfivarecargo27 DOUBLE PRECISION,
                   rlfdescuento105  DOUBLE PRECISION,
                   rlfrecargo105 DOUBLE PRECISION,
                   rflivadescuento105  DOUBLE PRECISION,
                                   rlfivarecargo105  DOUBLE PRECISION,
                                   rlftotaliva  DOUBLE PRECISION,
                                   rlftotalimpuesto DOUBLE PRECISION,
                                   rlfivadescuento21 DOUBLE PRECISION,
                                   idrlfprecarga BIGINT, 
                                   idcentrorlfprecarga INTEGER,
                                   -- <---> BelenA agrego
                                   impdebcred DOUBLE PRECISION

                   );       
   CREATE TEMP TABLE temp_actividad(idrecepcion bigint,
                idcentroregional integer,
                rlfaiva21 double precision,
                rlfaiva105 double precision,
                rlfaiva27 double precision,
                rlfanetoiva105 double precision,
                rlfanetoiva21 double precision,
                rlfanetoiva27 double precision,
                rlfanogravado double precision,
                rlfapercepciones double precision,
                rlfaretganancias double precision,
                rlfarlfpiibbneuquen double precision,
                rlfarlfpiibbrionegro double precision,
                rlfarlfpiibbotrajuri double precision,
                rlfadescuento21 double precision,
                rlfarecargo21 double precision,
                rlfaivadescuento21 double precision,
                rlfaivarecargo21 double precision,
                rlfadescuento27 double precision,
                rlfarecargo27 double precision,
                rlfaivadescuento27 double precision,
                rlfaivarecargo27 double precision,
                rlfadescuento105 double precision,
                rlfarecargo105 double precision,
                rlfaivadescuento105 double precision,
                rlfaivarecargo105 double precision,
                rlfaexento double precision,
                rlfadescuentoexento double precision,
                rlfarecargoexento double precision,
                                rlfaretiva double precision,
                idactividad integer NOT NULL,
                catgasto integer NOT NULL,
                idrlfprecarga BIGINT, 
                                idcentrorlfprecarga INTEGER,
                -- <---> BelenA agrego
                rlfaimpdebcred double precision
                );
   CREATE TEMP TABLE temprecepcioncc (        
                   idrecepcion INTEGER,       
                   idcentroregional INTEGER DEFAULT centro(),       
                   idcentrocosto INTEGER DEFAULT 1,       
                   monto DOUBLE PRECISION 
                    );   

   CREATE TEMP TABLE tempactividadcentroscosto (
                   idrecepcion bigint,
                   idcentroregional integer,
                   idcentrocosto integer NOT NULL,
                   accmonto double precision,
                   idactividad integer NOT NULL,
                   catgasto integer,
                   accidporcentaje double precision,
                   idrlfprecarga BIGINT, 
                                   idcentrorlfprecarga INTEGER
                );
   CREATE TEMP TABLE temprlfformpago (
                                   idrecepcion bigint,
                                   idcentroregional integer,
                                   idvalorescaja integer,
                                   rlffpmonto double precision,
                                   idreclibrofact_formpago bigint, 
                                   idcentroreclibrofact_formpago INTEGER,
                                   idrlfprecarga BIGINT, 
                                   idcentrorlfprecarga INTEGER
                                );
ELSE 
   DELETE FROM temprecepcion;
   DELETE FROM temp_actividad;
   DELETE FROM tempactividadcentroscosto;
   DELETE FROM temprecepcioncc;
DELETE FROM temprlfformpago;

END IF;

SELECT INTO rcatgasto * FROM rlf_precargaactividad 
    WHERE idrlfprecarga=rfiltros.idrlfprecarga AND idcentrorlfprecarga=rfiltros.idcentrorlfprecarga;

--KR 28-12-20 Tomo la actividad con mayor monto para guardarla en la cabecera de reclibrofact. Esto luego afecta el reporte de la liq de IVA
SELECT  INTO ractividad  max(pamonto), idactividad FROM rlf_precarga NATURAL JOIN rlf_precargaactividad WHERE idrlfprecarga=rfiltros.idrlfprecarga AND idcentrorlfprecarga=rfiltros.idcentrorlfprecarga GROUP BY idactividad ;

INSERT INTO temprecepcion (movctacte,idrecepcion,idcentroregional, fechavenc, numfactura, monto, numeroregistro, anio,idprestador, idlocalidad,     
    idtipocomprobante,idcentroregionalresumen, idrecepcionresumen, clase, montosiniva, descuento, recargo, exento, fechaemision,     
    fechaimputacion,  condcompra, talonario, iva21, iva105, iva27, letra, netoiva105, netoiva21, netoiva27, nogravado,     
    numero, obs, percepciones, puntodeventa, retganancias, retiibb, retiva, subtotal, tipocambio, tipofactura,fecharecepcion,accion,rlfpiibbneuquen,rlfpiibbrionegro,rlfpiibbotrajuri,rlfdescuento21,rlfrecargo21,
    rlfivadescuento21,rlfivarecargo21,idpresupuesto,idcentropresupuesto,rlfdescuento27,rlfrecargo27,rlfivadescuento27,rlfivarecargo27,rlfdescuento105,rlfrecargo105,rflivadescuento105,rlfivarecargo105,rlftotaliva,
    rlftotalimpuesto,idrlfprecarga,idcentrorlfprecarga, idtiporecepcion,catgasto,idactividad,impdebcred)

SELECT rlfp_movctacte,case when nullvalue(idrecepcion) then 0 ELSE idrecepcion END ,case when nullvalue(reclibrofact.idcentroregional) then idcentrorlfprecarga ELSE reclibrofact.idcentroregional END,rlf_precarga.fechavenc,rlf_precarga.numfactura,rlfpmonto,case when nullvalue(numeroregistro) then null ELSE numeroregistro END, case when nullvalue(anio) then null ELSE anio END , rlf_precarga.idprestador,rlf_precarga.idlocalidad,rlf_precarga.idtipocomprobante,rlf_precarga.idcentroregionalresumen,rlf_precarga.idrecepcionresumen,rlf_precarga.clase
,rlf_precarga.montosiniva,rlfpdescuentoexento
,rlfprecargoexento,rlfpexento,rlf_precarga.fechaemision,
    case when nullvalue(reclibrofact.fechaimputacion) then rlf_precarga.fechaimputacion ELSE reclibrofact.fechaimputacion END ,rlf_precarga.condcompra,rlf_precarga.talonario,rlf_precarga.iva21,rlf_precarga.iva105,rlf_precarga.iva27,rlf_precarga.letra,rlf_precarga.netoiva105,rlf_precarga.netoiva21,rlf_precarga.netoiva27,   rlf_precarga.nogravado,rlf_precarga.numero,rlf_precarga.obs,rlf_precarga.percepciones,rlf_precarga.puntodeventa,rlf_precarga.retganancias,rlf_precarga.retiibb,rlf_precarga.rlfretiva,rlf_precarga.subtotal,rlf_precarga.tipocambio,rlf_precarga.tipofactura,
    rlf_precarga.fecharecepcion,rfiltros.accion, rlf_precarga.rlfpiibbneuquen,rlf_precarga.rlfpiibbrionegro,rlf_precarga.rlfpiibbotrajuri,rlf_precarga.rlfpdescuento21,rlf_precarga.rlfprecargo21,rlfpivadescuento21,rlfpivarecargo21,idpresupuesto,idcentropresupuesto,rlfpdescuento27,rlfprecargo27,rlfpivadescuento27,rlfpivarecargo27,
    rlfpdescuento105,rlfprecargo105,rlfpivadescuento105,rlfpivarecargo105,rlfptotaliva,rlfptotalimpuesto,idrlfprecarga,idcentrorlfprecarga,case when rlf_precarga.idtipocomprobante=3 then 3 else 6 end,rcatgasto.catgasto,ractividad.idactividad, rlf_precarga.impdebcred 
FROM rlf_precarga
LEFT JOIN reclibrofact USING(idrlfprecarga,idcentrorlfprecarga)
WHERE idrlfprecarga=rfiltros.idrlfprecarga AND idcentrorlfprecarga=rfiltros.idcentrorlfprecarga;
 

INSERT INTO temp_actividad(rlfaiva21 ,rlfaiva105 ,rlfaiva27,rlfanetoiva105,rlfanetoiva21 ,rlfanetoiva27,rlfanogravado ,rlfapercepciones,rlfaretganancias ,rlfarlfpiibbneuquen ,
    rlfarlfpiibbrionegro,rlfarlfpiibbotrajuri ,rlfadescuento21 ,rlfarecargo21 ,rlfaivadescuento21 ,rlfaivarecargo21 ,rlfadescuento27 ,rlfarecargo27 ,rlfaivadescuento27 ,rlfaivarecargo27 ,rlfadescuento105 ,
    rlfarecargo105 ,rlfaivadescuento105 ,rlfaivarecargo105 ,rlfaexento ,rlfadescuentoexento ,rlfarecargoexento ,idactividad ,catgasto,idrlfprecarga,idcentrorlfprecarga,rlfaretiva,rlfaimpdebcred)
SELECT paiva21 , paiva105 ,paiva27 ,panetoiva105 ,panetoiva21 ,panetoiva27 ,panogravado ,papercepciones ,paretganancias ,parlfpiibbneuquen ,parlfpiibbrionegro ,parlfpiibbotrajuri ,padescuento21 ,parecargo21,
    paivadescuento21 ,paivarecargo21 ,padescuento27 ,parecargo27 ,paivadescuento27 ,paivarecargo27 ,padescuento105 ,parecargo105 ,paivadescuento105 ,paivarecargo105 ,paexento ,padescuentoexento ,parecargoexento ,
    idactividad ,catgasto ,idrlfprecarga,idcentrorlfprecarga,paretiva,paimpdebcred
    FROM rlf_precargaactividad 
    WHERE idrlfprecarga=rfiltros.idrlfprecarga AND idcentrorlfprecarga=rfiltros.idcentrorlfprecarga;

INSERT INTO  tempactividadcentroscosto (idcentrocosto ,accmonto ,idactividad ,catgasto ,accidporcentaje,idrlfprecarga,idcentrorlfprecarga)
SELECT  idcentrocosto,iccmonto,idactividad,catgasto,idporcentaje,idrlfprecarga,idcentrorlfprecarga
FROM rlf_precargaitemscentroscosto
WHERE idrlfprecarga=rfiltros.idrlfprecarga AND idcentrorlfprecarga=rfiltros.idcentrorlfprecarga; 

INSERT INTO temprecepcioncc (idcentrocosto ,monto )   
SELECT idcentrocosto,SUM(iccmonto )
FROM rlf_precargaitemscentroscosto
WHERE idrlfprecarga=rfiltros.idrlfprecarga AND idcentrorlfprecarga=rfiltros.idcentrorlfprecarga
GROUP BY idcentrocosto; 

INSERT INTO temprlfformpago (idvalorescaja ,rlffpmonto,idrlfprecarga,idcentrorlfprecarga )   
SELECT idvalorescaja ,rlfpfpmonto,idrlfprecarga,idcentrorlfprecarga
FROM rlf_precarga_formpago
WHERE idrlfprecarga=rfiltros.idrlfprecarga AND idcentrorlfprecarga=rfiltros.idcentrorlfprecarga;
  

IF rfiltros.accion ilike 'aprobar' THEN
    SELECT INTO elnumeroregistro * FROM mesaentrada_abmrecepcion();
END IF;
RETURN elnumeroregistro;
END;
$function$
