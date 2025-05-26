CREATE OR REPLACE FUNCTION public.mesaentrada_cambiarestadocomprobanteprecarga(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
    
--RECORD 
  rfiltros RECORD;  
  relestado RECORD;  
  respconcil RECORD;
--VARIABLES
  vusuario INTEGER; 
  vtipoestadofactura INTEGER; 
  elnroregistro VARCHAR;
  vtexto TEXT;
BEGIN

     EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
     SELECT INTO vusuario * FROM sys_dar_usuarioactual();

     IF rfiltros.accion = 'aprobar' THEN
         vtipoestadofactura = 13;
     END IF;
     IF rfiltros.accion = 'rechazar' THEN
         vtipoestadofactura = 5;
     END IF;
     IF rfiltros.accion = 'precargar' THEN
         vtipoestadofactura = 12;
     END IF;
      IF rfiltros.accion = 'eliminar' THEN
         vtipoestadofactura = 14;
     END IF;
     SELECT INTO relestado * FROM rlf_precarga_estado NATURAL JOIN tipoestadosfactura WHERE nullvalue(rlfpefechafin) AND idrlfprecarga=rfiltros.idrlfprecarga AND idcentrorlfprecarga=rfiltros.idcentrorlfprecarga;
     IF (relestado.tipoestadofactura = vtipoestadofactura ) THEN
      RAISE EXCEPTION 'EL COMPROBANTE YA SE ENCUENTRA (%)',relestado.estadofacturadesc;
     END IF;

--RAISE EXCEPTION 'rfiltros (%)',rfiltros;

    SELECT INTO  respconcil reclibrofact_esposiblemodificarestado(concat('{idrlfprecarga=',rfiltros.idrlfprecarga,', idcentrorlfprecarga=',rfiltros.idcentrorlfprecarga,'}')) as semodifica;
    IF( not nullvalue(respconcil.semodifica) )THEN
            --BelenA: El mensaje del RAISE ahora sera dependiendo del mensaje que te devuelve en el respconcil. TK 6092
            RAISE EXCEPTION '%',respconcil.semodifica;
    ELSE

             UPDATE rlf_precarga_estado SET rlfpefechafin= now() WHERE nullvalue(rlfpefechafin) AND idrlfprecarga=rfiltros.idrlfprecarga AND idcentrorlfprecarga=rfiltros.idcentrorlfprecarga;
             INSERT INTO rlf_precarga_estado(idrlfprecarga,idcentrorlfprecarga, rlfpedescripcion, rlfpeidusuario,tipoestadofactura)
                VALUES(rfiltros.idrlfprecarga::bigint,rfiltros.idcentrorlfprecarga::integer, concat('Se modifica el estado desde SP cambiarestadocomprobanteprecarga'), vusuario, vtipoestadofactura::integer);
              IF (rfiltros.accion = 'aprobar') THEN 
              SELECT INTO elnroregistro * FROM mesaentrada_aprobarprecarga(pfiltros);
              END IF;
               IF (rfiltros.accion = 'eliminar') THEN 

                     CREATE TEMP TABLE temprecepcion (              paraauditoria BOOLEAN,          movctacte BOOLEAN DEFAULT false,            idrecepcion INTEGER,            fechavenc DATE,             numfactura BIGINT,          monto DOUBLE PRECISION,         numeroregistro BIGINT,          idprestador BIGINT,         idlocalidad INTEGER,            idtipocomprobante INTEGER,          idtiporecepcion INTEGER DEFAULT 6,          idcentroregional INTEGER DEFAULT centro(),          idcentroregionalresumen INTEGER,            idrecepcionresumen INTEGER,         anio INTEGER DEFAULT date_part('year'::text, ('now'::text)::date),          clase VARCHAR(1),           montosiniva DOUBLE PRECISION,           descuento DOUBLE PRECISION,         recargo DOUBLE PRECISION,           exento DOUBLE PRECISION,            fechaemision DATE,          fechaimputacion DATE,           catgasto INTEGER,           condcompra INTEGER,         talonario INTEGER,          iva21 DOUBLE PRECISION,         iva105 DOUBLE PRECISION,            iva27 DOUBLE PRECISION,         letra CHAR(1),          netoiva105 DOUBLE PRECISION,            netoiva21 DOUBLE PRECISION,         netoiva27 DOUBLE PRECISION,         nogravado DOUBLE PRECISION,         numero VARCHAR(8),          obs VARCHAR(255),           percepciones DOUBLE PRECISION,          puntodeventa VARCHAR(5),            retganancias DOUBLE PRECISION,          retiibb DOUBLE PRECISION,           retiva DOUBLE PRECISION,            subtotal DOUBLE PRECISION,          tipocambio DOUBLE PRECISION,            tipofactura VARCHAR,            fecharecepcion DATE,            accion VARCHAR,             idjurisdiccion INTEGER ,            idactividad INTEGER,            rlfpiibbneuquen DOUBLE PRECISION,           rlfpiibbrionegro DOUBLE PRECISION,          rlfpiibbotrajuri DOUBLE PRECISION ,            impdebcred  DOUBLE PRECISION ); 

        INSERT INTO temprecepcion (idrecepcion,idcentroregional, fechavenc, numfactura, monto, numeroregistro, anio,idprestador, idlocalidad,       idtipocomprobante,idcentroregionalresumen, idrecepcionresumen, clase, montosiniva, descuento, recargo, exento, fechaemision,        fechaimputacion, catgasto, condcompra, talonario, iva21, iva105, iva27, letra, netoiva105, netoiva21, netoiva27, nogravado,         numero, obs, percepciones, puntodeventa, retganancias, retiibb, retiva, subtotal, tipocambio, tipofactura,fecharecepcion,accion,idjurisdiccion,idactividad,rlfpiibbneuquen,rlfpiibbrionegro,rlfpiibbotrajuri,impdebcred)    
        (

        select r.idrecepcion,r.idcentroregional, fechavenc, numfactura, monto, numeroregistro, anio,idprestador, idlocalidad,       idtipocomprobante,idcentroregionalresumen, idrecepcionresumen, clase, montosiniva, descuento, recargo, exento, fechaemision, fechaimputacion, catgasto, condcompra, talonario, iva21, iva105, iva27, letra, netoiva105, netoiva21, netoiva27, nogravado,        numero, obs, percepciones, puntodeventa, retganancias, retiibb, retiva, subtotal, tipocambio, tipofactura,rr.fecha as fecharecepcion,'eliminacion' as accion,idjurisdiccion,idactividad,rlfpiibbneuquen,rlfpiibbrionegro,rlfpiibbotrajuri,impdebcred

        from reclibrofact as r 
        natural join prestador as p             
        join recepcion rr on (r.idrecepcion=rr.idrecepcion and r.idcentroregional=rr.idcentroregional)          
        where idrlfprecarga=rfiltros.idrlfprecarga AND idcentrorlfprecarga=rfiltros.idcentrorlfprecarga

        );
                IF FOUND THEN
                    SELECT INTO elnroregistro * FROM mesaentrada_eliminarrecepcion();

               END IF;

              END IF;

    END IF;

 

return elnroregistro;
END;

$function$
