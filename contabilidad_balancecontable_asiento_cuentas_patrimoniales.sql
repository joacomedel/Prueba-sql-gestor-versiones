CREATE OR REPLACE FUNCTION public.contabilidad_balancecontable_asiento_cuentas_patrimoniales(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
      rfiltros RECORD;
      rusuario RECORD;
      rejercicio RECORD;
      parametro  character varying;
	  cursor_sumasysaldo refcursor; 
	  renglon_sys RECORD;
	  elconcepto  character varying;
	  elasiento  varchar;
	  salida boolean;
	  diferencia 	double precision;
BEGIN
---SELECT contabilidad_balancecontable_asiento_cuentas_patrimoniales('{idejerciciocontable=8}')
       salida = false;
	   diferencia = 0;
       SELECT INTO rusuario * FROM log_tconexiones WHERE idconexion=current_timestamp;
       IF NOT FOUND THEN
     
             rusuario.idusuario = 25;

       END IF;

       EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
       -- Con el id del ejercicio contable se busca la información para generar el reporte correspondiente al balance de sumas y saldos

       SELECT INTO rejercicio * , extract('year' from ecfechahasta) as anio,  to_char(ecfechahasta, 'DD/MM/YYYY') as fecha_formato FROM contabilidad_ejerciciocontable   WHERE idejerciciocontable = rfiltros.idejerciciocontable;
       
       -- El ejercicio contable debe estar cerrado
       IF not nullvalue(rejercicio.eccerrado) THEN 
                    -- 1 genero la descripcion del asiento
			        elconcepto = concat('Fecha al ',rejercicio.fecha_formato ,'. Concepto: Cierre de Cuentas Patrimoniales ',rejercicio.anio,'.');
			
		     		/* Creo las temporales para generar el asiento manual  */
		    		IF (iftableexists('tasientogenerico') ) THEN
                   		DROP TABLE tasientogenerico  ;
            		END IF;
	  
		     		-- 2 - Genero la temporal de la cabecera del asiento
	  				 CREATE TEMP TABLE tasientogenerico (   
						 fechaimputa date,
						 agdescripcion character varying,
						 idcomprobantesiges character varying(200) DEFAULT '0|0',
						 idasientogenericotipo integer DEFAULT 1,
						 idasientogenericocomprobtipo integer DEFAULT 6,
						 idasientogenerico integer,
						 idcentroasientogenerico integer);
						 
              		 IF (iftableexists('tasientogenericoitem') ) THEN
                       		DELETE FROM tasientogenericoitem;
             		 END IF;
					 CREATE TEMP TABLE tasientogenericoitem (    
						 acimonto double precision NOT NULL,
						 nrocuentac character varying NOT NULL,
						 acidescripcion character varying,
						 acid_h character varying(1) NOT NULL	 );
			
			
			
		             -- 3 -Guardo los datos	Cierre Ejercicio: Cuentas Patrimoniales
					INSERT INTO tasientogenerico (fechaimputa,agdescripcion,idasientogenerico,idcentroasientogenerico) 
					VALUES(rejercicio.ecfechahasta,elconcepto,NULL,NULL);
   
					-- 4 busco los datos de las cuentas contables vinculadas al ejercicio
                 	parametro =concat( '{salidaExcelSigesconmultivac=true, fechaHasta=', rejercicio.ecfechahasta  , ', fechaDesde=', rejercicio.ecfechadesde ,', cuenta=TODAS, idcuenta=0, titulo=BALANCE CONTABLE , salidaExcel=true, salidaExcelSiges=true, agrupa=false, nrofolio=0, modulo=Todos}');
                 	perform contabilidad_balancecontable_contemporal(parametro);
				 	-- recorro cada uno de los iten del suma y saldo y genero la minuta de imputacion.
				 	-- SOLO se deben tener en cuenta las cuentas que comienzan con 1/2/3/6
			
				 	OPEN cursor_sumasysaldo  FOR SELECT * FROM temp_contabilidad_balancecontable_contemporal 
				 	WHERE codcuenta ilike '1%'
				        OR codcuenta ilike '2%'
						OR (codcuenta ilike '3%'AND codcuenta<>'30230') 
						OR codcuenta ilike '6%'
						 ;
		            FETCH cursor_sumasysaldo INTO renglon_sys;
                
				 	WHILE  found LOOP
                               --- incorporo cada una de las impu
							   --- Si el saldo es Negativo esa cuenta debe ir al DEBE
				               --- Si el saldo es POSITIVO esa cuenta debe ir al HABER
							   IF not nullvalue(renglon_sys.saldo) THEN
							             IF( renglon_sys.saldo > 0 ) THEN 
										      INSERT INTO tasientogenericoitem (nrocuentac,acimonto ,acidescripcion,acid_h) 
											  values (  renglon_sys.codcuenta::integer ,renglon_sys.saldo,elconcepto,'H');
											  
		                       					/*INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) 
												VALUES (renglon_sys.codcuenta::integer  ,renglon_sys.codcuenta::varchar ,'0', renglon_sys.saldo);*/
		                                 END IF;
										 IF( renglon_sys.saldo < 0 ) THEN 
		                       					INSERT INTO tasientogenericoitem (nrocuentac,acimonto ,acidescripcion,acid_h) 
												values (  renglon_sys.codcuenta::integer, abs(renglon_sys.saldo),elconcepto,'D');
												/*INSERT INTO tempordenpagoimputacion (codigo, nrocuentac,debe ,haber) 
	             VALUES (renglon_sys.codcuenta::integer  ,renglon_sys.codcuenta::varchar , abs(renglon_sys.saldo),'0');*/
		                                 END IF;
										   diferencia = diferencia + renglon_sys.saldo;
					             END IF; 					  
                 FETCH cursor_sumasysaldo INTO renglon_sys;
                 END LOOP;
				 
				 -- La diferencia debe incorporarse a la cuenta 30240 
				 IF (diferencia > 0 ) THEN 
				 		INSERT INTO tasientogenericoitem (nrocuentac,acimonto,acid_h,acidescripcion) 
	             		VALUES ('30230',abs(diferencia) ,'D',elconcepto);
				 ELSE 
						INSERT INTO tasientogenericoitem (nrocuentac,acimonto,acid_h,acidescripcion) 
	             		VALUES ('30230',abs(diferencia) ,'H',elconcepto);
				 END IF;
				 
				 
				 -- genero el asiento
                    SELECT INTO elasiento asientogenerico_crear() as comprobante;
            	 ---SELECT INTO laordenpago  generarordenpagogenerica() AS comprobante;
				 
				  -- me aseguro que el asiento quede con fecha deseada. Seguramente el ejercicio esta cerrado x lo que pone por defecto la fecha del primer dia del ejercicio siguiente
                 UPDATE asientogenerico SET agfechacontable = rejercicio.ecfechahasta 
                 WHERE   idasientogenerico*100+idcentroasientogenerico = elasiento;

       ELSE 
                 -- Si el ejercicio contable no esta cerrado, doy un error
                 RAISE EXCEPTION ' Debe cerrar el ejercicio contable  %', concat(rfiltros.idejerciciocontable);

       END IF;
       return elasiento;
END;
$function$

