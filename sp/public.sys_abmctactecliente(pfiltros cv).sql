CREATE OR REPLACE FUNCTION public.sys_abmctactecliente(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE 
--RECORD
        rfiltros RECORD;
        rctactecliente RECORD;
        rcliente RECORD;
--VARIABLES
	vidusuario integer;
        vrespuesta VARCHAR;

BEGIN


vidusuario = sys_dar_usuarioactual();

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

SELECT INTO rcliente * FROM clientectacte LEFT JOIN clientectacteestado USING(nrocliente,barra) where nrocliente =lpad(rfiltros.nrocliente::text, 8, '0') AND barra = rfiltros.barra and nullvalue(cccefechafin);
IF FOUND and rcliente.idestadotipo= rfiltros.idestadotipo THEN 
      vrespuesta = concat ('Ya realizo el tramite de ', CASE WHEN rfiltros.idestadotipo=8 THEN ' alta ' WHEN rfiltros.idestadotipo=9 THEN ' baja ' END, ' con anterioridad. ');
ELSE  

    IF NOT nullvalue(rcliente.idclientectacte) THEN
           UPDATE clientectacte SET cccdtohaberes = case when rfiltros.cccdtohaberes ilike 'true' then TRUE ELSE FALSE END WHERE nrocliente =lpad(rfiltros.nrocliente::text, 8, '0') AND barra = rfiltros.barra;
    ELSE 
          INSERT INTO clientectacte(nrocliente, barra,cccidusuario,cccdtohaberes) VALUES(lpad(rfiltros.nrocliente::text, 8, '0')

--'08353588'
, rfiltros.barra,vidusuario,case when rfiltros.cccdtohaberes ilike 'true' then TRUE ELSE FALSE END);
    END IF;
    
    --por ahora y por defecto la forma de pago es descuento por haberes
  IF not nullvalue(rfiltros.idformapagoctacte) THEN 
    UPDATE clientectacteestado set cccefechafin = now() where nullvalue(cccefechafin) and nrocliente =rfiltros.nrocliente AND barra = rfiltros.barra;
   
    INSERT INTO clientectacteestado (ccceidusuario,idformapagoctacte,nrocliente,barra,idestadotipo ) VALUES(vidusuario, rfiltros.idformapagoctacte,lpad(rfiltros.nrocliente::text, 8, '0'),rfiltros.barra, rfiltros.idestadotipo);
    vrespuesta = concat ('Se dio de ', CASE WHEN rfiltros.idestadotipo=8 THEN ' alta ' WHEN rfiltros.idestadotipo=9 THEN ' baja ' END, ' correctamente. ');
       
  END IF;
 
END IF;



return vrespuesta; 
END;$function$
