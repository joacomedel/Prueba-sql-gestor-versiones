CREATE OR REPLACE FUNCTION public.generarprestamocuotas(integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Se registran los datos de un prestamo : Fecha del Prestamo,Tipo de Prestamo ( Asistencial, Plan de Pagos, Turismo)
 * Se vincula a su deuda origen
 * Segun el tipo de prestamo, se genera la informacion de cada una de las cuotas
 * En la cuenta corriente del afiliado :
 * Se ingresan los datos de la cuota:Monto, Numero de Cuota,Fecha Probable de Pago, Si es un anticipo
 * Se ingresa los datos del interes:Monto,Numero de Cuota a la que se aplica,Fecha Probable de Pago
 *
 * Datos entrada: TABLA tempconfiguracionprestamo
 *                tipodoc,nrodoc ,
 *                cantidadcuotas,
 *                idsolicitudfinanciacion,
 *				  idcentrosolicitudfinanciacion,
 *				  importetotal,
 *				  intereses,
 *				  idusuario,
 *				  importecuota
 * Parametro $1 que contiene el id del tipo de prestamo
 * Valor retornado: identificacion del  prestamo generado
*/

DECLARE

		cursorconfprestamo CURSOR FOR SELECT * FROM tempconfiguracionprestamo;
		rconfprestamo RECORD;
	    tipoprestamo alias for $1;
	    codprestamo integer;
	    codconcepto integer;
	    fechapagoprob date;
	    conceptomovimiento varchar;
	    nrocuentacontablecuota varchar;
	    nrocuentacontableintereses varchar;
            nrocuentacontableivaintereses varchar;
	    codcomprobantetipos integer;
	    idprestamocuota integer;
	    movconceptocuota varchar;
	    movconceptointeres varchar;
	    codcomprobante integer;
	    indice integer;
	    desplazamiento integer;
        mes integer;	
        impinteres double precision;
        impivainteres double precision;
            fechavto Date;
           diaconfiguracion date;
       dia integer;
       resp boolean;
       elconsumo record;
       valicuotaiva double precision;

       nop integer;
       elidiva  integer;
       elidcentroprestamo integer;
       eliddeuda bigint;
       elidcuentacorrienteconceptotipo  integer;
rcuentacorrienteconceptotipo record;
        

/*REGISTROS*/
       rcuentadeuda RECORD; 
       rorigenctacte RECORD;
       rccconceptotipo RECORD;
BEGIN
--VAS 04-04-2022 Se pone en en prodccion PP
           codprestamo = null; 
           nrocuentacontableivaintereses = '20821';

           OPEN cursorconfprestamo;
           FETCH cursorconfprestamo INTO rconfprestamo;
            
           --KR 30-05-22 Busco si el afiliado es adherente o afiliado
           CREATE TEMP TABLE tempcliente ( nrocliente character varying NOT NULL, barra bigint NOT NULL );
           INSERT INTO tempcliente(nrocliente,barra) VALUES(rconfprestamo.nrodoc,rconfprestamo.tipodoc);
           SELECT INTO rorigenctacte split_part(origen,'|',1) as origentabla,split_part(origen,'|',2)::bigint as clavepersonactacte,split_part(origen,'|',5)::integer as centroclavepersonactacte 
		FROM (SELECT verifica_origen_ctacte() as origen ) as t;
           DROP TABLE tempcliente;

           -- INICIO VAS Busco la configuracion de los prestamos (PP =3 9/03/2022) (PT = 1 01/08/2022) busco la configuraciones 
           SELECT INTO rcuentacorrienteconceptotipo * 
           FROM cuentacorrienteconceptotipo 
           JOIN tipoiva USING (idiva)
           WHERE idprestamotipos = tipoprestamo --  configuracion de tipo de prestamo  
                 AND nullvalue(ccctfechahasta)  -- configuracion  vigente
              	 AND nullvalue(ccctconfigdefecto);  -- configuracion por defecto
           -- FIN VAS Busco la configuracion de los prestamos (PP =3 9/03/2022) (PT = 1 01/08/2022) busco la configuraciones 




           IF tipoprestamo =  3 THEN -- PP : Plan pago cuenta corriente

                 -- codconcepto =374;
                  conceptomovimiento = 'Cuota prestamo por Plan pago cuenta corriente ';
                  codcomprobantetipos = 17;
                 
                  SELECT INTO rcuentadeuda * FROM pagocuentacorriente WHERE nullvalue(idmovimiento);
                  nrocuentacontablecuota = rcuentadeuda.nrocuentac;
                 
                   --MaLapi 19-12-2019 Para los Planes de Pago y Prestamos Asistenciales la alicuota de los intereses es 10.5
                   -- valicuotaiva = 0.105;
      
               
                   valicuotaiva = rcuentacorrienteconceptotipo.porcentaje;
                   elidiva = rcuentacorrienteconceptotipo.idiva;
                   codconcepto = rcuentacorrienteconceptotipo.idconcepto;

                   nrocuentacontableivaintereses = rcuentacorrienteconceptotipo.ccctiva_nrocuentac;
                   nrocuentacontableintereses = rcuentacorrienteconceptotipo.ccctinteres_nrocuentac;
                
                   --Malapi 28-07-2014 Agrego en la tabla de configuracion de los prestamos que no son de turismo la fecha de inicio del prestamo
                   IF not nullvalue(rconfprestamo.fechainipago) THEN 
                        dia =  extract(day from  rconfprestamo.fechainipago);
                        diaconfiguracion = rconfprestamo.fechainipago;
                   ELSE
                        dia =  extract(day from now());
                        diaconfiguracion = now();
                   END IF;
                   IF dia >=22   THEN
                       fechavto = diaconfiguracion +  interval '1 month';
                   ELSE
                       fechavto = diaconfiguracion;
                   END IF;

            END IF;
            IF tipoprestamo =  4 THEN     --Plan pago Asistencial
                  
                 rcuentacorrienteconceptotipo.idprestamotipos = 4;
                 conceptomovimiento = 'Cuota prestamo Asistencial ';
                 codcomprobantetipos = 18;
                  -- nrocuentacontablecuota = '123456'; --------VER CC
                 -- nrocuentacontablecuota = '123456';
--  cambie por Ds.x Prest.Esp.Documenta el dia 14/10/2011
                  nrocuentacontablecuota = '10342';
             

     --MaLapi 19-12-2019 Para los Planes de Pago y Prestamos Asistenciales la alicuota de los intereses es 10.5
                  valicuotaiva = 0.105;
                  
                  --VAS 210322 
                  elidiva = 3;



                --Modificado el 12-02-16. Antes  nrocuentacontableintereses = '40605'
          
                  nrocuentacontableintereses = '10342';
                 codconcepto =373;
                  --Malapi 28-07-2014 Agrego en la tabla de configuracion de los prestamos que no son de turismo la fecha de inicio del prestamo
                  IF not nullvalue(rconfprestamo.fechainipago) THEN 
                        dia =  extract(day from rconfprestamo.fechainipago);
                        diaconfiguracion = rconfprestamo.fechainipago;
                  ELSE
                        dia =  extract(day from now());
                        diaconfiguracion = now();
                  END IF;
                  IF dia >=22   THEN
                       fechavto = diaconfiguracion +  interval '1 month';
                  ELSE
                       fechavto = diaconfiguracion;
                  END IF;
--vas 9/03/22
 nrocuentacontableivaintereses = nrocuentacontableintereses ;

            END IF;
            IF tipoprestamo =  1 THEN     --Plan pago Turismo

                  valicuotaiva = rcuentacorrienteconceptotipo.porcentaje;
                  elidiva = rcuentacorrienteconceptotipo.idiva;
                  codconcepto = rcuentacorrienteconceptotipo.idconcepto;

                  nrocuentacontableivaintereses = rcuentacorrienteconceptotipo.ccctiva_nrocuentac;
                  nrocuentacontableintereses = rcuentacorrienteconceptotipo.ccctinteres_nrocuentac;
              
                 
                  conceptomovimiento = 'Cuota prestamo Turismo ';
                  codcomprobantetipos = 7;
                  nrocuentacontablecuota = '10333'; --------VER CC
                  -- Modificado el 12-02-16. Antes  nrocuentacontableintereses = '40605'
                  -- vas 010822 nrocuentacontableintereses = '10333'; --------VER CC
                  -- vas 010822codconcepto =360;
                  --MaLapi 19-12-2019 Por el momento, sigue siento del 21%
                  -- vas 010822 valicuotaiva = 0.21;
                   --VAS 210322 
                  -- vas 010822 elidiva = 2;

                 --rconfprestamo.fvtocuotauno
                 fechavto = rconfprestamo.fvtocuotauno;
                 if iftableexistsparasp('tempconsumoturismo') then
                    SELECT INTO elconsumo * FROM tempconsumoturismo LEFT JOIN consumoturismo using (idconsumoturismo,idcentroconsumoturismo);
                    IF not nullvalue(elconsumo.idprestamo) THEN
                           codprestamo =elconsumo.idprestamo;
                           elidcentroprestamo =elconsumo.idcentroprestamo;
                    END IF;

                 END IF;

--vas 9/03/22
 --- nrocuentacontableivaintereses = nrocuentacontableintereses ;
            END IF;

           -- Ingresa la informacion del prestamo si no es una actualizacion
           IF (nullvalue(codprestamo)) THEN
                        INSERT INTO prestamo(idprestamotipos, tipodoc, nrodoc,fechaprestamo,importeprestamo, idcentroprestamo)
                        VALUES(tipoprestamo,rconfprestamo.tipodoc, rconfprestamo.nrodoc,NOW(),rconfprestamo.importetotal,Centro());
                        codprestamo = currval('public.prestamo_idprestamo_seq');
                        elidcentroprestamo = centro(); 
                           -- Ingresa el primer estado del prestamo 1-Generado
                        INSERT INTO prestamoestado(idprestamo,idcentroprestamo,idprestamoestadotipos ,pefechaini	)
                        VALUES (codprestamo,elidcentroprestamo ,1,NOW());

           ELSE
                           -- Ingresa el primer estado del prestamo 4- Actualizado
                        UPDATE prestamoestado SET pefechafin = now() WHERE idcentroprestamo = elidcentroprestamo and  idprestamo = codprestamo;
                        INSERT INTO prestamoestado(idprestamo,idcentroprestamo,idprestamoestadotipos ,pefechaini,pefechafin	)
                        VALUES (codprestamo,elidcentroprestamo,4,NOW(),NOW());
                        -- Ingresa el primer estado del prestamo 1-Generado
                        INSERT INTO prestamoestado(idprestamo,idcentroprestamo,idprestamoestadotipos ,pefechaini)
                        VALUES (codprestamo,elidcentroprestamo,1,NOW());
           END IF;
          
             IF tipoprestamo = 3 or tipoprestamo = 4 THEN
                SELECT INTO resp * FROM movimientofondonuevo('prestamo', concat(codprestamo,'|',centro()));
             
             END IF;
             
           if rconfprestamo.importeanticipo <> 0 THEN
              -- Insercion de las cuotas del prestamo
               INSERT INTO prestamocuotas(idcomprobantetipos,idprestamo,idcentroprestamo,idcentroprestamocuota,importecuota,interes,importeinteres, anticipo,fechapagoprobable)
               VALUES (codcomprobantetipos,codprestamo,elidcentroprestamo, Centro(),rconfprestamo.importeanticipo, 0,0,true,NOW());
               idprestamocuota = currval('prestamocuotas_idprestamocuotas_seq');

               -- Insercion de la info de la cuota
               movconceptocuota = concat(conceptomovimiento,'. Prestamo Nº ', trim(to_char(codprestamo,'999999999999')) ,'. Anticipo ');
               codcomprobante = idprestamocuota *10 + centro();
               IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
		  INSERT INTO cuentacorrientedeuda (tipodoc,nrodoc, fechamovimiento,importe,idcentrodeuda,idctacte,idcomprobantetipos,movconcepto,nrocuentac,saldo,idcomprobante, idconcepto )
                  VALUES( rconfprestamo.tipodoc,rconfprestamo.nrodoc, NOW(),rconfprestamo.importeanticipo, centro(), concat(rconfprestamo.nrodoc,rconfprestamo.tipodoc), codcomprobantetipos::integer,  movconceptocuota, nrocuentacontablecuota, rconfprestamo.importeanticipo,codcomprobante, codconcepto );
               END IF;
               IF rorigenctacte.origentabla = 'clientectacte' THEN 
		  INSERT INTO ctactedeudacliente (idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo)
		VALUES(codcomprobantetipos::integer,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte , NOW(),movconceptocuota
		,nrocuentacontablecuota,rconfprestamo.importeanticipo, codcomprobante,rconfprestamo.importeanticipo);
               END IF;

             IF ( rcuentacorrienteconceptotipo.idprestamotipos = 3  OR rcuentacorrienteconceptotipo.idprestamotipos = 1
)THEN
                   IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
                          eliddeuda = currval('cuentacorrientedeuda_iddeuda_seq');
                          INSERT INTO cuentacorrientedeuda_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo, ccdcreacion )
                          VALUES(eliddeuda   , centro(), rcuentacorrienteconceptotipo.idcuentacorrienteconceptotipo,NOW());

                   ELSE 
                        eliddeuda = currval('ctactedeudacliente_iddeuda_seq');
                       
                        INSERT INTO ctactedeudacliente_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo)
                          VALUES(eliddeuda   , centro(), rcuentacorrienteconceptotipo.idcuentacorrienteconceptotipo);

                   END IF;
                   
               END IF;


            END IF;
            -- Creo cada una de las cuotas de un prestamo en cuentacorrientedeuda y sus intereses
            -- RECORDAR :Si es un prestamo de turismo la primer cuota es un anticipo

            fechapagoprob = CAST(concat(substr(fechavto,0,5),'-' , substr(fechavto,6,2),'-' ,'22') AS DAte);
            --indice = 1;
            --WHILE (indice <= rconfprestamo.cantidadcuotas ) LOOP
            FOR indice IN 1..rconfprestamo.cantidadcuotas LOOP
                -- Insercion de las cuotas del prestamo

               INSERT INTO prestamocuotas(idcomprobantetipos,idprestamo,idcentroprestamo,idcentroprestamocuota,importecuota,interes,importeinteres, anticipo,fechapagoprobable)
               VALUES (codcomprobantetipos,codprestamo, elidcentroprestamo, Centro(),rconfprestamo.importecuota,rconfprestamo.intereses, 0      ,false,fechapagoprob);
               idprestamocuota = currval('prestamocuotas_idprestamocuotas_seq');

               -- Insercion de la info de la cuota
               movconceptocuota = concat(conceptomovimiento,'. Prestamo Nº ', trim(to_char(codprestamo,'999999999999')) ,'. Cuota Nº ' , trim(to_char(indice,'999999999')));
               codcomprobante = idprestamocuota *10 + centro();
               IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
				INSERT INTO cuentacorrientedeuda (tipodoc,nrodoc,fechamovimiento,importe,idcentrodeuda,idctacte,idcomprobantetipos,movconcepto,nrocuentac,saldo,idcomprobante,idconcepto )
               	VALUES(rconfprestamo.tipodoc,rconfprestamo.nrodoc, fechapagoprob, rconfprestamo.importecuota , centro(), concat(rconfprestamo.nrodoc,rconfprestamo.tipodoc), codcomprobantetipos, movconceptocuota, nrocuentacontablecuota, rconfprestamo.importecuota, codcomprobante, codconcepto );
               END IF;
               IF rorigenctacte.origentabla = 'clientectacte' THEN 
		  INSERT INTO ctactedeudacliente (idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo )
	        VALUES(codcomprobantetipos,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte, fechapagoprob, movconceptocuota, nrocuentacontablecuota,rconfprestamo.importecuota ,codcomprobante, rconfprestamo.importecuota );              
		 
               END IF;
              -- Agrega VAS (PP=09/03/22 )(PT01082022)
     
              
               IF ( rcuentacorrienteconceptotipo.idprestamotipos = 3   OR rcuentacorrienteconceptotipo.idprestamotipos = 1
)THEN
                   IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
                          eliddeuda = currval('cuentacorrientedeuda_iddeuda_seq');
                          INSERT INTO cuentacorrientedeuda_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo, ccdcreacion )
                          VALUES(eliddeuda   , centro(), rcuentacorrienteconceptotipo.idcuentacorrienteconceptotipo,NOW());
                    ELSE 
                        eliddeuda = currval('ctactedeudacliente_iddeuda_seq');
                       
                        INSERT INTO ctactedeudacliente_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo)
                          VALUES(eliddeuda   , centro(), rcuentacorrienteconceptotipo.idcuentacorrienteconceptotipo);
 
                   END IF;
                  
               END IF;


                -- Insercion de la info de los intereses
               if rconfprestamo.intereses <> 0 THEN
                      desplazamiento =  indice -1;
                        -- Calculo del interes sobre saldo
                      impinteres = round (cast(((rconfprestamo.cantidadcuotas - desplazamiento) * rconfprestamo.importecuota * rconfprestamo.intereses) as numeric),4);
                      impivainteres = 0;                  
						movconceptointeres = concat(conceptomovimiento,'. Prestamo Nº ', trim(to_char(codprestamo,'999999999999')) ,'. Interes de Cuota Nº ' , trim(to_char(indice,'999999999')));
                        -- interes calculado sobre el total impinteres = rconfprestamo.importecuota *rconfprestamo.intereses;
                      IF rorigenctacte.origentabla = 'afiliadoctacte' THEN    
			INSERT INTO cuentacorrientedeuda (tipodoc,nrodoc,fechamovimiento,  importe, idcentrodeuda, movconcepto, idctacte,idcomprobantetipos,nrocuentac,  saldo,  idcomprobante,  idconcepto)
                        VALUES(rconfprestamo.tipodoc,rconfprestamo.nrodoc,  fechapagoprob,impinteres,centro(), movconceptointeres,  concat(rconfprestamo.nrodoc,rconfprestamo.tipodoc), codcomprobantetipos, nrocuentacontableintereses,  impinteres, codcomprobante,  codconcepto);
                      END IF;
                      IF rorigenctacte.origentabla = 'clientectacte' THEN 
                          INSERT INTO ctactedeudacliente(idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo)
                        VALUES(codcomprobantetipos,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte,  fechapagoprob,movconceptointeres, nrocuentacontableintereses,impinteres, codcomprobante, impinteres);
                      END IF;
                         -- Agrega VAS (PP=09/03/22)(PT=010822) 
                         IF (rcuentacorrienteconceptotipo.idprestamotipos = 3  OR rcuentacorrienteconceptotipo.idprestamotipos = 1 
)THEN 
                            IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
                                  eliddeuda = currval('cuentacorrientedeuda_iddeuda_seq');
                                 INSERT INTO cuentacorrientedeuda_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo, ccdcreacion )
                                 VALUES(eliddeuda   , centro(),rcuentacorrienteconceptotipo.idcuentacorrienteconceptotipo_interes,NOW());
                            ELSE 
                              eliddeuda = currval('ctactedeudacliente_iddeuda_seq');
                        
                              INSERT INTO ctactedeudacliente_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo)
                              VALUES(eliddeuda   , centro(), rcuentacorrienteconceptotipo.idcuentacorrienteconceptotipo);
 

                            END IF;
                             
                         END IF;


                        -- IF tipoprestamo = 3 or tipoprestamo = 4 THEN
                         impivainteres =  round((impinteres * valicuotaiva)::numeric,4);      
                         -- Malapi 19/09/2016 Los planes de pago y los prestamos tienen iva en los intereses. 
                         -- Malapi 19/10/2016 Todos los prestamos tienen intereses. 
                         IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
			    INSERT INTO cuentacorrientedeuda(tipodoc,nrodoc,fechamovimiento,  importe, idcentrodeuda, movconcepto, idctacte,idcomprobantetipos,nrocuentac,  saldo,  idcomprobante,  idconcepto)
                        VALUES(rconfprestamo.tipodoc,rconfprestamo.nrodoc,  fechapagoprob,impivainteres,centro(), concat(movconceptointeres, ' Iva ',round((valicuotaiva*100)::numeric,2),'%') ,   concat(rconfprestamo.nrodoc,rconfprestamo.tipodoc), codcomprobantetipos, nrocuentacontableivaintereses,  impivainteres, codcomprobante,  codconcepto);
                         END IF;
                         IF rorigenctacte.origentabla = 'clientectacte' THEN 
			   INSERT INTO ctactedeudacliente(idcomprobantetipos,idclientectacte,idcentroclientectacte,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo)
                        VALUES(codcomprobantetipos,rorigenctacte.clavepersonactacte,rorigenctacte.centroclavepersonactacte, fechapagoprob,concat(movconceptointeres, ' Iva ',round((valicuotaiva*100)::numeric,2),'%') , nrocuentacontableivaintereses, impivainteres,codcomprobante, impivainteres);
                         END IF;
                           -- Agrega VAS (PP=09/03/22)(PT010822) 
                        
                         IF ( rcuentacorrienteconceptotipo.idprestamotipos = 3  OR rcuentacorrienteconceptotipo.idprestamotipos = 1
)THEN 
                             IF rorigenctacte.origentabla = 'afiliadoctacte' THEN 
                                   eliddeuda = currval('cuentacorrientedeuda_iddeuda_seq');
                                    INSERT INTO cuentacorrientedeuda_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo, ccdcreacion )
                                    VALUES(eliddeuda   , centro(),rcuentacorrienteconceptotipo.idcuentacorrienteconceptotipo_ivainteres	,NOW());
                             ELSE 
                               eliddeuda = currval('ctactedeudacliente_iddeuda_seq');
                       
                               INSERT INTO ctactedeudacliente_ext (iddeuda  ,idcentrodeuda,  idcuentacorrienteconceptotipo)
                          VALUES(eliddeuda   , centro(), rcuentacorrienteconceptotipo.idcuentacorrienteconceptotipo);
 

                             END IF;
                             
                         END IF;


                          --VAS 210322    pcidiva=elidiva 
                        UPDATE prestamocuotas 
                        set importeinteres = impinteres + impivainteres ,   pcidiva=elidiva 
                        WHERE idprestamocuotas = idprestamocuota and idcentroprestamocuota = centro();

              END IF;
              fechapagoprob = fechapagoprob + interval '1 month';
            END LOOP;
 CLOSE cursorconfprestamo;
RETURN codprestamo;
END;
$function$
