CREATE OR REPLACE FUNCTION public.contabilidad_balancecontable_asiento_patrimoniales_apertura(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
      rfiltros RECORD;
      rusuario RECORD;
      rejercicio RECORD;
	  rejercicio_siguiente  RECORD;
      parametro  character varying;
	  cursor_sumasysaldo refcursor; 
	  renglon_sys RECORD;
	  elconcepto  character varying;
	  elasiento  varchar;
	  salida boolean;
	  diferencia 	double precision;
BEGIN
---SELECT contabilidad_balancecontable_asiento_patrimoniales_apertura('{idejerciciocontable=8,idasientocierre=xxxxx}')

/** 
El asiento de apertura se corresponde con el asiento de cierre de manera tal que:
Si en el asiento de cierre una cuenta afecta al debe en el de apertura afecta al haber y viceversa 
*/
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
       IF  nullvalue(rejercicio.eccerrado) THEN 
	   		 -- Si el ejercicio contable no esta cerrado, doy un error
             RAISE EXCEPTION ' Debe cerrar el ejercicio contable  %', concat(rfiltros.idejerciciocontable);
	   ELSE 
	   		SELECT INTO rejercicio_siguiente * , extract('year' from ecfechahasta) as anio,  to_char(ecfechahasta, 'DD/MM/YYYY') as fecha_formato 
			FROM contabilidad_ejerciciocontable   
			WHERE 	idejerciciocontable > rfiltros.idejerciciocontable
			ORDER BY ecfechadesde
			LIMIT 1;
      		IF NOT FOUND THEN --- si no hay un ejercicio siguiente creado no va a ser posible crear el asiento de apertura
				 RAISE EXCEPTION ' No exite un ejercicio contable para el asiento de apertura';
			ELSE
                
                   -- 1 genero la descripcion del asiento
			        elconcepto = concat('Fecha al ',rejercicio.fecha_formato ,'. Concepto: Apertura de Cuentas Patrimoniales ',rejercicio_siguiente.anio,' correspondiente al asiento de cierre:',substr( rfiltros.idasientocierre,0,length( rfiltros.idasientocierre)-1),'-',substr(rfiltros.idasientocierre,length(rfiltros.idasientocierre)-1,length(rfiltros.idasientocierre)) );
			
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
			
			
			
		             -- 3 -Guardo los datos	Cierre Ejercicio: Cuentas Patrimoniales idasientocierre
					INSERT INTO tasientogenerico (fechaimputa,agdescripcion,idasientogenerico,idcentroasientogenerico) 
					VALUES(rejercicio_siguiente.ecfechadesde,elconcepto,NULL,NULL);
   
   	 				INSERT INTO tasientogenericoitem (acimonto ,nrocuentac,acidescripcion,acid_h) 
					(   SELECT acimonto,nrocuentac,elconcepto,CASE WHEN acid_h='D' THEN 'H' WHEN  acid_h='H' THEN 'D' END
						FROM asientogenericoitem 
						WHERE idasientogenerico*100+idcentroasientogenerico::numeric = rfiltros.idasientocierre
					);
								
   
				 -- genero el asiento
                    SELECT INTO elasiento asientogenerico_crear() as comprobante;
            	 ---SELECT INTO laordenpago  generarordenpagogenerica() AS comprobante;
				 
				  -- me aseguro que el asiento quede con fecha deseada. Seguramente el ejercicio esta cerrado x lo que pone por defecto la fecha del primer dia del ejercicio siguiente
                 UPDATE asientogenerico SET agfechacontable = rejercicio_siguiente.ecfechadesde 
                 WHERE   idasientogenerico*100+idcentroasientogenerico = elasiento;

     		 END IF;
       END IF;
       return elasiento;
END;$function$
