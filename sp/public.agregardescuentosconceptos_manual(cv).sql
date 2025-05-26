CREATE OR REPLACE FUNCTION public.agregardescuentosconceptos_manual(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* Por parametro se recibo la informacion necesaria para procesar un descuento no procesado por algun motivo
Carga los conceptos 387 y 372 de la liquidacion para ser usada en la imputacion de cuentas corrientes.
Utiliza la informacion de las tablas dh49 para la liquidacion y dh21 para los datos de los aportes
*/
DECLARE
	alta refcursor;
    cursorauxi refcursor;
    elemcursor record;
    elem RECORD;
    rinforme RECORD;
	resultado boolean;
	rfiltros RECORD;
BEGIN
	-- Recuperar la info enviada por parametro
	---mesingreso , anioingreso , nrolegajo
	EXECUTE sys_dar_filtros($1) INTO rfiltros;
	resultado = true;


	RAISE NOTICE '(%)/(%) legajo (%)',  rfiltros.mesingreso , rfiltros.anioingreso ,rfiltros.nrolegajo;
	
	/*Ingreso los aportes de las personas que no fueron reportadas en el informe*/
	OPEN alta FOR SELECT dh21.*,nrodoc,tipodoc,tipoempleado,nrodoc::integer * 10 + tipodoc as idctacte
    			  FROM dh21
    			  NATURAL JOIN (
         				SELECT legajosiu,legajosiu as nrolegajo,nrodoc,tipodoc FROM afilidoc
         				UNION
         				SELECT legajosiu,legajosiu as nrolegajo,nrodoc,tipodoc FROM afilinodoc
         				UNION
         				SELECT legajosiu,legajosiu as nrolegajo,nrodoc,tipodoc FROM afiliauto
         				UNION
         				SELECT legajosiu,legajosiu as nrolegajo,nrodoc,tipodoc FROM afilirecurprop
          			) as t
    				NATURAL JOIN (SELECT idcargo as nrocargo,legajosiu,tipodesig as tipoempleado FROM cargo ) as cargo
    				LEFT JOIN infomeerrordescuentosplanilla USING(legajosiu,mesingreso,anioingreso)
    				WHERE dh21.mesingreso  = rfiltros.mesingreso 
					      AND dh21.anioingreso  = rfiltros.anioingreso
   					      AND (dh21.nroconcepto = 372 OR dh21.nroconcepto = 387 )
    					  AND dh21.nrolegajo =  rfiltros.nrolegajo   
    					  AND nullvalue(infomeerrordescuentosplanilla.legajosiu);

	FETCH alta INTO elem;
	WHILE  found LOOP
       		SELECT INTO rinforme * 
			FROM informedescuentoplanillav2
            WHERE nroliquidacion = elem.nroliquidacion
                            AND idcargo = elem.nrocargo
                            AND importe = elem.importe
                            AND mes = elem.mesingreso
                            AND anio = elem.anioingreso;
       		IF NOT FOUND THEN
              		--SELECT * FROM informedescuentoplanillav2 WHERE mes = 7 AND anio=2023 AND nrodoc='37603510'
					
					INSERT INTO informedescuentoplanillav2 (idinforme,nroliquidacion,legajosiu,concepto,idcargo,importe,fechaingreso,mes,anio,tipoempleado,importeimputado,nrodoc,tipodoc)
            		VALUES (nextval('informedescuentoplanilla_idinforme_seq'),elem.nroliquidacion,elem.nrolegajo,elem.nroconcepto,elem.nrocargo,elem.importe,CURRENT_DATE,elem.mesingreso,elem.anioingreso,elem.tipoempleado,elem.importe,elem.nrodoc,elem.tipodoc);
            		RAISE NOTICE 'Se ingreso info informedescuentoplanillav2  (%)', currval('informedescuentoplanilla_idinforme_seq');
					
					INSERT INTO cuentacorrientepagos(idcomprobantetipos,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,tipodoc,idctacte,idcentropago)
            		VALUES (13,CURRENT_DATE,concat ( 'Descuento UNC liq ' , elem.nroliquidacion , ' cargo ' , elem.nrocargo , ' ' , elem.mesingreso , '/' , elem.anioingreso),10311,elem.importe*-1,currval('informedescuentoplanilla_idinforme_seq'),elem.importe*-1,elem.nroconcepto,elem.nrodoc,elem.tipodoc,elem.idctacte,centro());
					
					RAISE NOTICE 'Se ingreso info cuentacorrientepagos  (%)', concat ( 'Descuento UNC liq ' , elem.nroliquidacion , ' cargo ' , elem.nrocargo , ' ' , elem.mesingreso , '/' , elem.anioingreso) ;
			ELSE 
			        RAISE NOTICE 'Los datos se encuentran en informedescuentoplanillav2  nroliquidacion= (%) - nrocargo=(%) - importe=(%) - mesingreso= (%) - anioingreso=(%) ', elem.nroliquidacion,  elem.nrocargo,elem.importe,  elem.mesingreso, elem.anioingreso;
      		END IF;

	fetch alta into elem;
	END LOOP;
	CLOSE alta;
  
	return resultado;

END;
$function$
