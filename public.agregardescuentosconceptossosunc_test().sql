CREATE OR REPLACE FUNCTION public.agregardescuentosconceptossosunc_test()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
Carga los conceptos de la liquidacion para ser usada en la imputacion de cuentas corrientes.
*/
DECLARE
	alta refcursor;
    cursorauxi refcursor;
    elemcursor record;
    elem RECORD;
    datocliente  record;
    datoverificaafil record;
    rinforme RECORD;
resultado boolean;
    mesLiq INTEGER;
	anioLiq  INTEGER;
BEGIN

		resultado = true;
		/*Ingreso los descuentos de las personas que no fueron reportadas en el infomeerrordescuentosplanilla */
		OPEN alta FOR SELECT descuentososunc.*,nrodoc,tipodoc
                     ,CASE WHEN (idliquidaciontipo=1) THEN 'SOS' 
	             		   WHEN (idliquidaciontipo=2) THEN 'Farmacia' END  tipoempleado
					 ,nrodoc::integer * 10 + tipodoc as idctacte,legajosiu as nrolegajo
    		  		 FROM descuentososunc
    		  		 JOIN ca.liquidacion ON (nroliquidacion = idliquidacion)
    				--vas 110923 no tiene sentido corroborar la tabla xq si esta en descuento no se encuentra en infomeerrordescuentosplanilla  LEFT JOIN infomeerrordescuentosplanilla USING(legajosiu,mesingreso,anioingreso)
    				 WHERE true
     			  		   AND (descuentososunc.nroconcepto = 372 OR descuentososunc.nroconcepto=388 or descuentososunc.nroconcepto = 360 OR descuentososunc.nroconcepto = 387 OR descuentososunc.nroconcepto = 373 OR descuentososunc.nroconcepto = 374 );
    			  	---vas 110923	   AND nullvalue(infomeerrordescuentosplanilla.legajosiu); -- no fue reportado error 

	  FETCH alta INTO elem;
	  WHILE  found LOOP  ---- Por cada descuento realizado lo informo en informedescuentoplanillav2 y  ingreso movimiento en la cuenta corriente 
       			SELECT INTO rinforme * 
				FROM informedescuentoplanillav2
                WHERE nroliquidacion = elem.nroliquidacion
                            AND idcargo = elem.nrocargo
                            AND importe = elem.importe
                            AND mes = elem.mesingreso
                            AND anio = elem.anioingreso
                            AND concepto =elem.nroconcepto;
       		IF NOT FOUND THEN
         			INSERT INTO informedescuentoplanillav2
                     (idinforme,informedescuentoplanillatipo,nroliquidacion,legajosiu,concepto,idcargo,importe,fechaingreso,mes,anio,tipoempleado,importeimputado,nrodoc,tipodoc)
         			VALUES (nextval('informedescuentoplanilla_idinforme_seq'),2,elem.nroliquidacion,elem.nrolegajo,elem.nroconcepto,elem.nrocargo,elem.importe,CURRENT_DATE,elem.mesingreso,elem.anioingreso,elem.tipoempleado,elem.importe,elem.nrodoc,elem.tipodoc);
      		 	 
				 	IF( elem.tipoempleado = 'SOS') THEN  --- Es empleado de SOSUNC => cuenta corriente afiliado
--KR 06-12-22 TKT 5490 REClasificamos a 10201 para afiliados
           					INSERT INTO cuentacorrientepagos(idcomprobantetipos,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,tipodoc,idctacte,idcentropago)
           					VALUES (13,CURRENT_DATE,concat ( 'Descuento SOSUNC liq ' , elem.nroliquidacion , ' cargo ' , elem.nrocargo , ' ' , elem.mesingreso , '/' , elem.anioingreso),10201,elem.importe*-1,currval('informedescuentoplanilla_idinforme_seq'),elem.importe*-1,elem.nroconcepto,elem.nrodoc,elem.tipodoc,elem.idctacte,centro());

         			ELSE /* empleado de farmacia => cuenta corriente cliente */

           				  SELECT INTO  datocliente * 
						  FROM clientectacte 
						  NATURAL JOIN cliente 
						  WHERE  nrocliente=elem.nrodoc;
						  --KR 06-07-22 se modifica el nrocuentac a la que va el movimiento, Deudores por Asistencial Farmacia  // antes 10311
						  --KR 06-12-22 TKT 5490 REClasificamos a 10202 para adherentes
          		 	
						  INSERT INTO ctactepagocliente(idcomprobantetipos,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idclientectacte,idcentroclientectacte,idcentropago)
            	 		  VALUES (13,CURRENT_DATE,concat ( 'Descuento SOSUNC liq ' , elem.nroliquidacion , ' cargo ' , elem.nrocargo , ' ' , elem.mesingreso , '/' , elem.anioingreso),10202,elem.importe*-1,currval('informedescuentoplanilla_idinforme_seq'),elem.importe*-1,datocliente.idclientectacte,datocliente .idcentroclientectacte,centro());
         			END IF;

       		END IF;
fetch alta into elem;
END LOOP;
CLOSE alta;

/*Paso tambien ahora por parametro 1 si es descuento concepto de sosunc*/
	mesLiq = date_part('month', current_date -30)::integer; 
	 
	anioLiq = date_part('year', current_date - 30)::integer;
	 
	PERFORM asentarreciboenctactepagos_test(mesLiq,anioLiq,1);
--PERFORM asentarreciboenctactepagos(7,2019,1);

return resultado;

END;$function$
