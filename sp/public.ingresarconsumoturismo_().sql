CREATE OR REPLACE FUNCTION public.ingresarconsumoturismo_()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*  NUEVA FUNCION QUE VA A REEMPLAZAR ingresarconsumoturismo
 Funcion que ingresa el consumo de turismo para un afiliado en particular,
creando las cuotas que seran pagadas en cta cte 

MaLaPi 16-11-2021 Modifico para que solo genere las cuotas nuevamente si se trata de que cambio el importe o su configuracion 
*/
DECLARE

 elprestamo RECORD;
 lascuotas refcursor;
 unacuota RECORD;
 launidad RECORD;
 unvalor RECORD;
 elconsumo RECORD;
 elconsumoorig RECORD;
 laconfprest  RECORD;
 rconsumoturismovalores RECORD;
 rgrupoacompaniante RECORD;
 afiliado record;
 losacomp refcursor;
 losvalores refcursor;
 unacomp RECORD;
 idelprestamo BIGINT;
 idelcentroprestamo INTEGER;
 idconsumo BIGINT;
 cuentacontable VARCHAR;
 movconceptocuota VARCHAR;
 respuesta boolean;
 elinformefactorig refcursor;
losinformesfacturables refcursor;
 elnuevoinforme integer;
 actualizarinformegenerado boolean;
 cambiaelimporte boolean;
 elinformefactnuevo refcursor;
 unactainformenuevo  RECORD;
 unactainformeorig   RECORD;
 elidinformeorig integer;
     elidcentroinforig integer;
uninforme_ record;
 informe_ integer;
cinformesdiferencia refcursor;
 diferencia double precision;
 canttuplas integer;
 rconfiginicial RECORD;
 uninformecancela  RECORD;
 rvaloresnuevo RECORD;
BEGIN
     cuentacontable = '10363'; /*Alquileres a Cobrar*/
     actualizarinformegenerado = false;
--06-03-2015 Malapi agrega pues ya no se calcula la fecha de vto de la primera cuota en java
/*KR 09-12-20 modifico ya que por disposicion la fecha de vto de la primer cuota es 30 dias luego de que se contrata el servicio*/
SELECT INTO rconfiginicial *,/*case when fechaegreso <= date_trunc('month',fechaegreso)::date + integer '14'
THEN  date_trunc('month',fechaegreso)::date + integer '21'
ELSE  (date_trunc('month',fechaegreso)::date + integer '21' + interval '1 month')::date END*/

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


cambiaelimporte = TRUE;

--- MaLaPi 16-11-2021 Verifico si cambioaron los importes del prestamos
	PERFORM from generarprestamocuotas_simulacion(1); -- el tipoprestamos siempr es 1 - turismo
	SELECT INTO rvaloresnuevo * FROM (
	SELECT idprestamo,idcentroprestamo,count(idprestamo) as cantidadvigente,sum(importeinteres) as importeinteresvigente,sum(importecuota) as importecuotavigente
	FROM prestamocuotas 
	NATURAL JOIN tempconsumoturismo 
	WHERE nullvalue (pcborrado) 
	GROUP BY idprestamo,idcentroprestamo
	) as vigente
	NATURAL JOIN (
	SELECT idprestamo,idcentroprestamo,count(idprestamo) as cantidadnuevo,sum(importeinteres + CASE WHEN nullvalue(importeivainteres) then 0 else importeivainteres end) as importeinteresnuevo,sum(importecuota) as importecuotanuevo
	FROM temp_prestamocuotas 
	GROUP BY idprestamo,idcentroprestamo
	) as nuevo;
	
	IF FOUND THEN
		IF rvaloresnuevo.cantidadvigente = rvaloresnuevo.cantidadnuevo
			AND rvaloresnuevo.importeinteresvigente = rvaloresnuevo.importeinteresnuevo 
			AND rvaloresnuevo.importecuotavigente = rvaloresnuevo.importecuotanuevo
			THEN
			cambiaelimporte = FALSE;
		END IF;
	END IF;


     SELECT INTO elconsumo * FROM tempconsumoturismo;

     SELECT INTO laconfprest * FROM tempconfiguracionprestamo;

     SELECT INTO launidad * FROM turismounidad WHERE turismounidad.idturismounidad = elconsumo.idturismounidad;

     idelcentroprestamo = centro();

     /* Inserto los datos del prestamos */
     SELECT INTO elprestamo * FROM tempprestamo;

     /* Se trata de una actualizacion de un consumo turismo
           1- recupero los datos del consumo
           2- borro Grupo acompañante
           3- consumoturismo valores
           4- prestamos cuotas
     */
        IF (not  nullvalue (elconsumo.idconsumoturismo) )THEN
             SELECT INTO elconsumoorig * FROM consumoturismo
             WHERE idconsumoturismo =elconsumo.idconsumoturismo and  idcentroconsumoturismo = elconsumo.idcentroconsumoturismo;
             
             UPDATE consumoturismovalores SET ctvborrado = true
             WHERE idconsumoturismo =elconsumo.idconsumoturismo and  idcentroconsumoturismo = elconsumo.idcentroconsumoturismo;

             UPDATE grupoacompaniante SET gaborrado = true
             WHERE idconsumoturismo =elconsumo.idconsumoturismo and  idcentroconsumoturismo = elconsumo.idcentroconsumoturismo;

			IF cambiaelimporte THEN
             	UPDATE prestamocuotas SET pcborrado = NOW()
             	WHERE idprestamo = elconsumoorig.idprestamo and idcentroprestamo =  elconsumoorig.idcentroprestamo
                AND nullvalue(pcborrado);
			END IF;
				 
				 
             idelprestamo = elconsumoorig.idprestamo;
             idelcentroprestamo = elconsumoorig.idcentroprestamo;
  
            -- actualizo informacion del prestamo
             UPDATE prestamo SET  importeprestamo =laconfprest.importetotal 
                 WHERE idprestamo = elconsumoorig.idprestamo and idcentroprestamo =  elconsumoorig.idcentroprestamo;
        ELSE
             elconsumo.idcentroconsumoturismo = centro();
        END IF;

     /*  Pago del prestamo es en cuenta corriente
         Inserto las cuotas del prestamo, esto es independiente si es una actualizacion o nuevo
     */

     IF (  elconsumo.idformapago =3 ) THEN
	  	IF cambiaelimporte THEN
           SELECT INTO idelprestamo * FROM generarprestamocuotas(1);
           IF (not nullvalue (elconsumo.idconsumoturismo) )THEN -- si es una actualizacion del consumo hay que reimputar la ctacte
              SELECT INTO respuesta * FROM consumoturismoactualizartacte(elconsumo.idconsumoturismo,elconsumo.idcentroconsumoturismo);
           END IF;
		END IF;
     END IF;

     /* COnsumo con forma de pago efectivo */
     IF (elconsumo.idformapago =2 )THEN
            IF (nullvalue(elconsumo.idconsumoturismo)) THEN
               -- Ingresa la informacion del prestamo
               INSERT INTO prestamo(idprestamotipos, tipodoc, nrodoc,fechaprestamo,importeprestamo, idcentroprestamo)
               VALUES(1,laconfprest.tipodoc, laconfprest.nrodoc,NOW(),laconfprest.importetotal,Centro() );
               idelprestamo = currval('public.prestamo_idprestamo_seq');
               idelcentroprestamo = centro();
          
            END IF;
			IF cambiaelimporte THEN
            	INSERT INTO prestamocuotas(idcomprobantetipos,idformapagotipos,idprestamo,idcentroprestamo,idcentroprestamocuota,importecuota,interes, anticipo,fechapagoprobable)
            	VALUES (7,elconsumo.idformapago,idelprestamo,idelcentroprestamo, Centro(),laconfprest.importetotal, 0,true,NOW());
			END IF;

     END IF;
     IF ( idelprestamo <> 0  OR NOT nullvalue(elconsumo.idconsumoturismo) ) THEN
               /* Si no hay un consumo se crea el nuevo */
               IF (nullvalue(elconsumo.idconsumoturismo ))THEN
                             INSERT INTO consumoturismo (idconsumoturismo,idcentroconsumoturismo,
                                    idprestamo,idcentroprestamo,ctfehcingreso,ctfechasalida,cantdias,idturismounidad,ctdescuento,
                                    ctinformacioncontacto,nrocuentac)
                              VALUES(nextval('public.consumoturismo_idconsumoturismo_seq'),centro(),idelprestamo,idelcentroprestamo,NOW(),NOW(),0
                              ,elconsumo.idturismounidad,elconsumo.descuento,elconsumo.ctinformacioncontacto
                              ,elconsumo.nrocuentac);
                              idconsumo = currval('public.consumoturismo_idconsumoturismo_seq');

                              INSERT INTO consumoturismoestado(idconsumoturismo,idcentroconsumoturismo,idconsumoturismoestadotipos)
                              VALUES(idconsumo,centro(),1); -- El estado 1 es Generado
                ELSE
                              idconsumo = elconsumo.idconsumoturismo;
                              UPDATE consumoturismo SET ctinformacioncontacto = elconsumo.ctinformacioncontacto, 
                               ctdescuento= elconsumo.descuento, idturismounidad = elconsumo.idturismounidad
                              WHERE idconsumoturismo = elconsumo.idconsumoturismo AND idcentroconsumoturismo = elconsumo.idcentroconsumoturismo;
               END IF;
               /* Ingreso los valores a  consumoturismovalores */
                OPEN losvalores FOR SELECT * FROM tempconsumoturismo;
                FETCH losvalores INTO unvalor;
                WHILE  found LOOP
                                --Hay que verificar si hay que actualizar uno existente o crear nuevos o borrar los que no esten
                                IF (nullvalue(elconsumo.idconsumoturismo ) )THEN
                                   INSERT INTO consumoturismovalores(idconsumoturismo, idcentroconsumoturismo,  fechaegreso, fechaingreso,ctvcantdias,idturismounidadvalor
                                   )VALUES(idconsumo,  centro(),  unvalor.fechaegreso, unvalor.fechaingreso,  unvalor.cantdias, unvalor.idturismounidadvalor );
                                ELSE
                                     -- Si es una modificacion, ya se marcaron como borrados todos.
                                     SELECT INTO rconsumoturismovalores * 
									 FROM consumoturismovalores
                                     WHERE  idconsumoturismo = idconsumo
                                     AND idcentroconsumoturismo = elconsumo.idcentroconsumoturismo
                                     AND idturismounidadvalor = unvalor.idturismounidadvalor;
                                     IF FOUND THEN
                                              UPDATE  consumoturismovalores SET
                                                      fechaegreso =  unvalor.fechaegreso,
                                                      fechaingreso = unvalor.fechaingreso,
                                                      ctvcantdias = unvalor.cantdias,
                                                      ctvborrado = FALSE
                                              WHERE idconsumoturismo = idconsumo
                                                     AND idcentroconsumoturismo = elconsumo.idcentroconsumoturismo
                                                     AND idturismounidadvalor = unvalor.idturismounidadvalor;
                                     ELSE
                                         INSERT INTO consumoturismovalores(idconsumoturismo, idcentroconsumoturismo, fechaegreso,  fechaingreso, ctvcantdias, idturismounidadvalor
                                         )VALUES(idconsumo, elconsumo.idcentroconsumoturismo, unvalor.fechaegreso,unvalor.fechaingreso, unvalor.cantdias, unvalor.idturismounidadvalor);
                                     END IF;

                              END IF;
                FETCH losvalores INTO unvalor;
                END LOOP;
                CLOSE losvalores;

                /* Actualizacion de los datos del consumo */
                UPDATE consumoturismo SET ctfehcingreso=t.fingreso ,  ctfechasalida=t.fegreso , cantdias=t.cantd
                FROM (
                     SELECT MIN(fechaingreso)as fingreso, MAX(fechaegreso)as fegreso,SUM(ctvcantdias) as cantd
                     FROM consumoturismovalores
                     WHERE idconsumoturismo = idconsumo and idcentroconsumoturismo = centro()
                     )as t
                WHERE idconsumoturismo = idconsumo and idcentroconsumoturismo =centro();

                /*Calculo la cantidad de dias correctos*/
                UPDATE consumoturismo SET cantdias=ctfechasalida - ctfehcingreso
                WHERE idconsumoturismo = idconsumo and idcentroconsumoturismo =centro();
                /* Inserto los datos de las personas que acompañan */
                OPEN losacomp FOR SELECT * FROM tempgrupoacompaniante;
                FETCH losacomp INTO unacomp;
                WHILE  found LOOP
                       IF (nullvalue(elconsumo.idconsumoturismo) )THEN
                                INSERT INTO grupoacompaniante(idconsumoturismo,idcentroconsumoturismo,nrodoc,tipodoc,nombres,apellido,fechanac,invitado,idvinculo)
                                VALUES(idconsumo,centro(),unacomp.nrodoc,unacomp.tipodoc,unacomp.nombres,unacomp.apellido,unacomp.fechanac,unacomp.invitado,unacomp.idvinculo);
                       ELSE
                           --Si es una modificacion, se marco como borrado a todos el grupo acompaniante
                           SELECT INTO rgrupoacompaniante * FROM grupoacompaniante
                           WHERE idconsumoturismo = elconsumo.idconsumoturismo
                                 AND idcentroconsumoturismo = elconsumo.idcentroconsumoturismo
                                 AND nrodoc = unacomp.nrodoc AND tipodoc = unacomp.tipodoc;
                           IF FOUND THEN
                              UPDATE grupoacompaniante SET
                               nombres = unacomp.nombres ,apellido = unacomp.apellido ,fechanac = unacomp.fechanac ,invitado = unacomp.invitado
                               ,idvinculo = unacomp.idvinculo ,gaborrado = FALSE
                               WHERE idconsumoturismo = elconsumo.idconsumoturismo
                                     AND idcentroconsumoturismo = elconsumo.idcentroconsumoturismo
                                     AND nrodoc = unacomp.nrodoc AND tipodoc = unacomp.tipodoc;
                           ELSE
                               INSERT INTO grupoacompaniante(idconsumoturismo,idcentroconsumoturismo,nrodoc,tipodoc,nombres,apellido,fechanac,invitado,idvinculo)
                               VALUES(elconsumo.idconsumoturismo,elconsumo.idcentroconsumoturismo,unacomp.nrodoc,unacomp.tipodoc,unacomp.nombres,unacomp.apellido,unacomp.fechanac,unacomp.invitado,unacomp.idvinculo);
                     END IF;
                END IF;

                FETCH losacomp INTO unacomp;
                END LOOP;
                CLOSE losacomp;
              /* Si el consumo turismo fue actualizado*/
			   --MaLaPi 16-11-2021 Cambio los informes, solo su hay cambio de importes
			   IF cambiaelimporte THEN
			   			   IF (not nullvalue(elconsumo.idconsumoturismo) )THEN
							   -- 1 busco el informe facturacion turismo correspondiente al consumo turismo
							   OPEN elinformefactorig FOR
													SELECT  idtipofactura ,idformapagotipos, nrocuentac , SUM(importe) as importe , MAX(nroinforme) as nroinforme , MAX(idcentroinformefacturacion) as idcentroinformefacturacion
													   FROM informefacturacionturismo
													   NATURAL JOIN informefacturacion
													   NATURAL JOIN informefacturacionitem
													   JOIN informefacturacionestado USING(nroinforme,idcentroinformefacturacion)
													   WHERE idconsumoturismo =elconsumo.idconsumoturismo and idcentroconsumoturismo = elconsumo.idcentroconsumoturismo AND nullvalue(fechafin) AND idinformefacturacionestadotipo = 4
													   GROUP BY idtipofactura , nrocuentac,idformapagotipos;
								actualizarinformegenerado = true;

							   -- 2 cancelo los consumos que estan pendientes
							   OPEN losinformesfacturables FOR 
														SELECT informefacturacion.*
													   FROM informefacturacionturismo
													   NATURAL JOIN informefacturacion
													   NATURAL JOIN informefacturacionitem
													   JOIN informefacturacionestado USING(nroinforme,idcentroinformefacturacion)
													   WHERE idconsumoturismo =elconsumo.idconsumoturismo
															 and idcentroconsumoturismo = elconsumo.idcentroconsumoturismo
															 AND nullvalue(fechafin) AND idinformefacturacionestadotipo = 3;
							   FETCH losinformesfacturables INTO uninformecancela ;
							   WHILE FOUND LOOP
									SELECT INTO respuesta  cambiarestadoinformefacturacion (uninformecancela.nroinforme,uninformecancela.idcentroinformefacturacion,5,
										 concat('X Modificacion consumo turismo ',elconsumo.idconsumoturismo ,'-', elconsumo.idcentroconsumoturismo));
										  FETCH losinformesfacturables INTO uninformecancela ;
							   END LOOP;
							   CLOSE losinformesfacturables;


						  END IF;




						   /* Genero el informe de facturacion para Turismo*/
						  -- Recuperar la barra de la persona que corresponde a
						--KR 04-12-15  SELECT INTO afiliado * FROM persona WHERE nrodoc = elprestamo.nrodoc and  tipodoc = elprestamo.tipodoc;
							SELECT INTO afiliado * FROM cliente WHERE nrocliente = elprestamo.nrodoc and  barra = elprestamo.tipodoc;

						  -- parametros : $1 idconsumoturismo.$2 idcentroconsumoturismo,  $3 nrodoc, $4 barra,  $5 numero cuenta contable, $6 importeTotal, $7 tipofactura, $8 sidevuelveanticipo
						  SELECT INTO elnuevoinforme * FROM  generarinformeturismo_ (idconsumo::integer, centro(), elprestamo.nrodoc, afiliado.barra::integer,cuentacontable, elprestamo.importeprestamo::real,'FA'::varchar,0,elconsumo.idformapago);


						  CREATE TEMP TABLE ttinformefacturacionitem_ (eltipofac VARCHAR ,laformapago INTEGER,nroinforme INTEGER,nrocuentac varchar,cantidad INTEGER,importe DOUBLE PRECISION,descripcion VARCHAR,idiva INTEGER);
						  IF actualizarinformegenerado THEN
									 FETCH elinformefactorig INTO unactainformeorig;
									 WHILE  found LOOP
											elidinformeorig = unactainformeorig.nroinforme;
											elidcentroinforig = unactainformeorig.idcentroinformefacturacion;

										   SELECT INTO unactainformenuevo *
										   FROM informefacturacionitem NATURAL JOIN informefacturacion
										   WHERE nrocuentac = unactainformeorig.nrocuentac
												 and idformapagotipos = unactainformeorig.idformapagotipos
												 and idtipofactura =unactainformeorig.idtipofactura
												 and nroinforme =elnuevoinforme  and idcentroinformefacturacion =centro()  ;

										   -- Analizo las diferencia entre los importes de las cuentas
										   IF ( (not found )OR(unactainformenuevo.importe - unactainformeorig.importe) <0 )THEN
												  -- el informe original era mas caro para esa cuenta => NC x la dif
												  diferencia = unactainformenuevo.importe - unactainformeorig.importe;
												  INSERT INTO ttinformefacturacionitem_ (eltipofac,	laformapago ,nrocuentac ,cantidad ,importe ,descripcion,idiva)
												  VALUES ('NC', unactainformenuevo.idformapagotipos , unactainformenuevo.nrocuentac,1,abs(diferencia),unactainformenuevo.descripcion,unactainformenuevo.idiva);
										  ELSE
												  -- el informe original era menor para esa cuenta => FA x la diferencia
												  diferencia = unactainformenuevo.importe - unactainformeorig.importe;
												  IF ( diferencia<>0 )THEN

													   INSERT INTO ttinformefacturacionitem_ (eltipofac ,laformapago ,nrocuentac ,cantidad ,importe ,descripcion,idiva)
												  VALUES ('FA' , unactainformenuevo.idformapagotipos, unactainformenuevo.nrocuentac,1,abs(diferencia),unactainformenuevo.descripcion,unactainformenuevo.idiva);
												  END IF;

										   END IF ;

										   FETCH elinformefactorig INTO unactainformeorig;
									END LOOP;
									CLOSE elinformefactorig;

									--- Pongo todas las cuentas del nuevo informe que no estaban en el original
									INSERT INTO ttinformefacturacionitem_ (eltipofac ,laformapago ,nrocuentac ,cantidad ,importe ,descripcion,idiva)
									SELECT 'FA',idformapagotipos, nrocuentac,cantidad,importe , descripcion,idiva
									FROM informefacturacionitem
									NATURAL JOIN informefacturacion
									WHERE nroinforme =elnuevoinforme  and idcentroinformefacturacion =centro()
										  and (nrocuentac,idtipofactura) NOT IN (
											  SELECT nrocuentac,idtipofactura
											  FROM informefacturacionitem
											  NATURAL JOIN informefacturacion
											  WHERE nroinforme =elidinformeorig  and idcentroinformefacturacion =elidcentroinforig

										  );
									-- cancelo el informe generado y genero los comprobantes basados en las diferencias entre las cuentas
									--MaLaPi 19-11-2021 Dejo de cancelar el informe pues lo voy a eliminar.... solo se genero para buscar las diferencias
									--SELECT INTO respuesta * FROM cambiarestadoinformefacturacion (elnuevoinforme,centro(),5,concat('X Modificacion consumo turismo ',elconsumo.idconsumoturismo ,'-', elconsumo.idcentroconsumoturismo));
									
										DELETE FROM informefacturacionturismo WHERE nroinforme = elnuevoinforme AND idcentroinformefacturacion = centro();
										DELETE FROM informefacturacion  WHERE nroinforme = elnuevoinforme AND idcentroinformefacturacion = centro();


									 -- Creo los informe de facturacion necesarios
									 OPEN cinformesdiferencia FOR SELECT count(*)as cantidad, laformapago, eltipofac
																	 FROM ttinformefacturacionitem_
																	 WHERE importe <>0
																	 GROUP BY laformapago,eltipofac;
									 FETCH cinformesdiferencia INTO uninforme_;
									 WHILE FOUND LOOP
											   -- genero el informe
											   SELECT INTO informe_ *
											   FROM generarinformeturismointerno(elconsumo.idconsumoturismo,elconsumo.idcentroconsumoturismo
											   ,elprestamo.nrodoc, afiliado.barra::integer,uninforme_.eltipofac,uninforme_.laformapago);

											   -- verifico si existe la tabla ttinformefacturacionitem
											   if iftableexistsparasp('ttinformefacturacionitem') THEN
												  DELETE FROM ttinformefacturacionitem;
											   END IF;
											   -- la lleno con los item

											   INSERT INTO ttinformefacturacionitem (	nrocuentac ,cantidad ,importe ,descripcion,idiva)
											   SELECT nrocuentac ,cantidad ,importe ,descripcion,idiva
											   FROM ttinformefacturacionitem_
											   WHERE laformapago = uninforme_.laformapago
													 and  importe <>0
													 and eltipofac = uninforme_.eltipofac;

											   UPDATE ttinformefacturacionitem SET nroinforme =informe_;
											   SELECT INTO respuesta * FROM insertarinformefacturacionitem();

												-- dejo el informe en estado facturado
											--  SELECT INTO respuesta * FROM cambiarestadoinformefacturacion (informe_,centro(),3,concat('X diferencia de importes en mod. cons. turismo ',elconsumo.idconsumoturismo ,'-', elconsumo.idcentroconsumoturismo));

											   FETCH cinformesdiferencia INTO uninforme_;
									 END LOOP;
									 CLOSE cinformesdiferencia;
             		 END IF;
				 END IF; --Si cambia el importe
      END IF;
RETURN TRUE;
END;$function$
