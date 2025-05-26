CREATE OR REPLACE FUNCTION public.generarprestamocuotas_simulacion(tipoprestamo integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
/* 
 * Se generan los datos de lo que puede salir un prestamos segun tipo 
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
		rcuentadeuda RECORD; 
		rconfiginicial RECORD;
	    -- tipoprestamo alias for $1;
	    codprestamo integer;
	    fechapagoprob date;
	    codcomprobantetipos integer;
	    codcomprobante integer;
	    indice integer;
	    desplazamiento integer;
        impinteres double precision;
        impivainteres double precision;
        fechavto Date;
        diaconfiguracion date;
       dia integer;
       resp boolean;
       elconsumo record;
       valicuotaiva double precision;
       elidcentroprestamo integer;
       
BEGIN

CREATE TEMP TABLE temp_prestamocuotas AS 
SELECT idprestamocuotas,idprestamo,fechapagoprobable,importecuota,anticipo,idformapagotipos,idcentroprestamo,idcentroprestamocuota,interes,importeinteres,importeinteres as importeivainteres,idcomprobantetipos
 FROM prestamocuotas LIMIT 1
;

DELETE FROM temp_prestamocuotas;


/* Borrar esto cuando este en produccion, esto se debe ejecutar en el SP anterior */
	SELECT INTO rconfiginicial *,
	case when current_Date<= date_trunc('month',now()+interval '30' day )::date + integer '14'
		THEN  date_trunc('month',now()+interval '30' day )::date + integer '21'
		ELSE  (date_trunc('month',now()+interval '30' day )::date + integer '21' + interval '1 month')::date END as fechavtocuotauno
	FROM (
		SELECT min(fechaingreso) as fechaingreso, max(fechaegreso) as fechaegreso,sum(cantdias)  as cantdias
 		FROM tempconsumoturismo
		) as t;

	IF FOUND THEN 
		UPDATE tempconfiguracionprestamo SET fvtocuotauno = rconfiginicial.fechavtocuotauno;
	END IF;
           
		   codprestamo = null; 
           OPEN cursorconfprestamo;
           FETCH cursorconfprestamo INTO rconfprestamo;
            
            IF tipoprestamo =  3 THEN --Plan pago cuenta corriente
                  codcomprobantetipos = 17;
                  valicuotaiva = 0.105;
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
                  codcomprobantetipos = 18;
                  valicuotaiva = 0.105;
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

            END IF;
            IF tipoprestamo =  1 THEN     --Plan pago Turismo
                  codcomprobantetipos = 7;
                  valicuotaiva = 0.21;
				  fechavto = rconfprestamo.fvtocuotauno;
                 if iftableexistsparasp('tempconsumoturismo') then
                    SELECT INTO elconsumo * FROM tempconsumoturismo LEFT JOIN consumoturismo using (idconsumoturismo,idcentroconsumoturismo);
                    IF not nullvalue(elconsumo.idprestamo) THEN
                           codprestamo =elconsumo.idprestamo;
                           elidcentroprestamo =elconsumo.idcentroprestamo;
                    END IF;

                 END IF;
            END IF;
             
           if rconfprestamo.importeanticipo <> 0 THEN
              -- Insercion de las cuotas del prestamo
               INSERT INTO temp_prestamocuotas(idprestamocuotas,idcomprobantetipos,idprestamo,idcentroprestamo,idcentroprestamocuota,importecuota,interes,importeinteres, anticipo,fechapagoprobable)
               VALUES (1,codcomprobantetipos,codprestamo,elidcentroprestamo, Centro(),rconfprestamo.importeanticipo, 0,0,true,NOW());
            END IF;
            fechapagoprob = CAST(concat(substr(fechavto,0,5),'-' , substr(fechavto,6,2),'-' ,'22') AS DAte);
            FOR indice IN 1..rconfprestamo.cantidadcuotas LOOP
                -- Insercion de las cuotas del prestamo
               INSERT INTO temp_prestamocuotas(idprestamocuotas,idcomprobantetipos,idprestamo,idcentroprestamo,idcentroprestamocuota,importecuota,interes,importeinteres, anticipo,fechapagoprobable)
               VALUES (indice + 1,codcomprobantetipos,codprestamo, elidcentroprestamo, Centro(),rconfprestamo.importecuota,rconfprestamo.intereses, 0      ,false,fechapagoprob);
               if rconfprestamo.intereses <> 0 THEN
                        desplazamiento =  indice -1;
                        -- Calculo del interes sobre saldo
                        impinteres = round (cast(((rconfprestamo.cantidadcuotas - desplazamiento) * rconfprestamo.importecuota * rconfprestamo.intereses) as numeric),4);
                        impivainteres = 0;                  
						impivainteres =  round((impinteres * valicuotaiva)::numeric,4);      
                        UPDATE temp_prestamocuotas set importeinteres = impinteres, importeivainteres = impivainteres WHERE idprestamocuotas = indice+1 and idcentroprestamocuota = centro();
              END IF;
              fechapagoprob = fechapagoprob + interval '1 month';
            END LOOP;
 CLOSE cursorconfprestamo;
RETURN codprestamo;
END;$function$
