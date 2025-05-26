CREATE OR REPLACE FUNCTION public.guardardatosfacturareciprocidad()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

--VARIABLES
    
    nrocuentacontable VARCHAR;
    movimientoconcepto VARCHAR;
    idcuentacorriente VARCHAR;
    idcomprobanted INTEGER;
    descprestacion VARCHAR;
--REGISTROS

    regfac RECORD;
    regestadofac RECORD;
    esbenef RECORD; 
    rcolumna RECORD; 
    rprestadorreci RECORD;
--CURSORES

    cursorfac refcursor;
 
BEGIN
-- KR 21-07-20 es para asegurarnos QUE este la vinculacion de la reci al prestador. Al parecer este es es el problema por el que no se cargaban las ordenes de reci
    SELECT into rprestadorreci * FROM tempfacturareciprocidadinfo   
                              JOIN (SELECT idosreci, barra as barraos,mapeoprestadorosreci.idprestador FROM mapeoprestadorosreci JOIN osreci  using(idosreci, barra)) as t USING(idprestador)
       limit 1;
   if found then 





   OPEN cursorfac FOR SELECT * FROM tempfacturareciprocidadinfo   
                              JOIN (SELECT idosreci, barra as barraos,mapeoprestadorosreci.idprestador FROM mapeoprestadorosreci JOIN osreci  using(idosreci, barra)) as t USING(idprestador);
   
   FETCH cursorfac INTO regfac;
--MaLaPi 29/02/2016 Ya no se cambia mas el estado, se audita como una factura mas
--   SELECT INTO regestadofac * FROM facturareciprocidadinfo 
--   WHERE nroregistro = regfac.nroregistro AND anio=regfac.anio;
--   IF NOT FOUND THEN --es el primer dato cargado de la factura entonces le pongo estado 'En auditoria medica', id 9
--        INSERT INTO festados(fechacambio,nroregistro,anio,tipoestadofactura,observacion)
--        VALUES(CURRENT_DATE,regfac.nroregistro,regfac.anio,9,'Desde el SP guardardatosfacturareciprocidad');
--
--   END IF;
   WHILE FOUND LOOP

         INSERT INTO facturareciprocidadinfo(nroordenreci, 
                                             idosreci, 
                                             fechauso, 
                                             importetotal, 
                                             porcentaje, 
                                             importeafiliado, 
                                             nrodoc,    
                                             tipodoc,    
                                             barra,    
                                             fidtipoprestacion, 
                                             nroregistro, 
                                             observacionfri,   
                                             nroorden,
                                             centro,
                                             anio,
                                             barraosreci )  	 
         VALUES(regfac.nroordenreci,regfac.idosreci,regfac.fechauso,regfac.importetotal,regfac.porcentaje,
         regfac.importeafiliado,regfac.nrodoc,regfac.tipodoc,regfac.barra,regfac.fidtipoprestacion, regfac.nroregistro,regfac.observaciones,regfac.nroorden,
            regfac.centro,regfac.anio,regfac.barraos);
--      KR 29/02/2016 Le deuda se genera al momento de expender la orden
--  Se modifico el proceso desde el modulo de Auditoria de ordenes, para que Carola procese registros viejos, y se busca si existe el campo para 
--generar la deuda. 

  SELECT INTO rcolumna column_name 
    FROM information_schema.COLUMNS
      WHERE table_name = 'tempfacturareciprocidadinfo'  AND column_name='generadeuda';
 IF FOUND THEN 
   SELECT INTO descprestacion ftipoprestaciondesc FROM ftipoprestacion WHERE fidtipoprestacion= regfac.fidtipoprestacion;
         nrocuentacontable = '10311'; --Cta Cte Asistencial NQN
         movimientoconcepto = concat('Orden: ' ,to_char(regfac.nroorden::integer,'00000000'), '. Obra Social: ', regfac.abreviatura , '. Fecha Uso: ',regfac.fechauso ,'. Nro. Registro' , regfac.nroregistro , ' - ', regfac.anio, 'Prestacion: ', descprestacion
        ,' Obs. ' , CASE WHEN nullvalue(regfac.observaciones) THEN ' ' ELSE regfac.observaciones END);
         idcomprobanted =  currval('facturareciprocidadinfo_idfacturareciprocidadinfo_seq');

         SELECT INTO esbenef nrodoctitu, tipodoctitu 
         FROM benefsosunc   
         WHERE nrodoc=regfac.nrodoc AND tipodoc=regfac.tipodoc;
         IF FOUND THEN 
                  idcuentacorriente = to_number(esbenef.nrodoctitu,'99999999')*10+esbenef.tipodoctitu;
        
        	 INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
	 VALUES (31,esbenef.tipodoctitu,idcuentacorriente,now(),movimientoconcepto,nrocuentacontable,regfac.importeafiliado,idcomprobanted* 100 +centro(),regfac.importeafiliado,387,esbenef.nrodoctitu);
         ELSE 
                 idcuentacorriente = to_number(regfac.nrodoc,'99999999')*10+regfac.tipodoc;
        
        	 INSERT INTO cuentacorrientedeuda(idcomprobantetipos,tipodoc,idctacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc)
	 VALUES (31,regfac.tipodoc,idcuentacorriente,now(),movimientoconcepto,nrocuentacontable,regfac.importeafiliado,idcomprobanted* 100 +centro(),regfac.importeafiliado,387,regfac.nrodoc);
         END IF;

END IF;

   FETCH cursorfac INTO regfac;

    END LOOP;

    CLOSE cursorfac;

  ELSE 
     RAISE EXCEPTION 'R-001, La OSRECI no tiene la vinculacion al prestador. Informar a DTIC.(Idprestador,%)',rprestadorreci.idprestador;
  END IF;

return true;

END;$function$
