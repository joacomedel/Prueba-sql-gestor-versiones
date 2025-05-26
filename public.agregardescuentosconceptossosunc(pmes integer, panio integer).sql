CREATE OR REPLACE FUNCTION public.agregardescuentosconceptossosunc(pmes integer, panio integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
Carga los conceptos 387 y 372 de la liquidacion para ser usada en la imputacion de
cuentas corrientes.
Utiliza la informacion de las tablas dh49 para la liquidacion y dh21 para los datos de
los aportes
*/
DECLARE
alta refcursor;
    cursorauxi refcursor;
    elemcursor record;
    elem RECORD;
    rinforme RECORD;
--    pmes alias for $1;
--    panio alias for $2;
resultado boolean;
BEGIN

/*CREATE TEMP TABLE descuentososunc (	mesingreso INTEGER,	anioingreso INTEGER,	nroliquidacion INTEGER,	legajosiu INTEGER,	nrocargo INTEGER,	nroconcepto INTEGER,	importe NUMERIC(10,2),	tipodoc INTEGER,	nrodoc VARCHAR	) WITHOUT OIDS;
INSERT INTO descuentososunc VALUES (7,2016,516,990112,990112,387,757.36,1,'27091730');
*/

DELETE FROM infomeerrordescuentosplanilla;
/*Verifico las personas que deben ser informadas*/
OPEN cursorauxi FOR SELECT
	        legajosiu,nroliquidacion,nrocargo,importe,mesingreso,anioingreso
	            FROM
	            (
	            SELECT max(descuentososunc.mesingreso) as mesingreso,max(descuentososunc.anioingreso) as anioingreso,legajosiu as legajosiu,max(nroliquidacion) as nroliquidacion ,max(nrocargo) as nrocargo,sum(importe) as importe
	            FROM descuentososunc
	        --   WHERE  descuentososunc.mesingreso >= date_part('month', current_date -30) AND descuentososunc.anioingreso >= date_part('year', current_date - 30)
                  WHERE  descuentososunc.mesingreso >= pmes AND descuentososunc.anioingreso >= panio
	             AND (descuentososunc.nroconcepto = 388 or idconcepto=372 OR descuentososunc.nroconcepto = 387 or  descuentososunc.nroconcepto = 373 or  descuentososunc.nroconcepto = 374 )
	                  GROUP BY legajosiu
	            ) as personas
	            LEFT JOIN (
	              SELECT legajosiu,nrodoc,tipodoc FROM afilisos
	              ) as t
	              USING(legajosiu)
	             WHERE nullvalue(t.legajosiu);
FETCH cursorauxi INTO elemcursor;
WHILE found Loop
       --Reportarlo como que no existe en sosunc, o no esta bien cargado
       INSERT INTO infomeerrordescuentosplanilla (legajosiu,importe,mesingreso,anioingreso,nroliquidacion,nrocargo)
       VALUES(elemcursor.legajosiu,elemcursor.importe,elemcursor.mesingreso,elemcursor.anioingreso,elemcursor.nroliquidacion,elemcursor.nrocargo);
FETCH cursorauxi INTO elemcursor;
END LOOP;
CLOSE cursorauxi;
resultado = true;
/*Ingreso los aportes de las personas que no fueron reportadas en el informe*/
OPEN alta FOR SELECT descuentososunc.*,nrodoc,tipodoc,tipoempleado,nrodoc::integer * 10 + tipodoc as idctacte,t.nrolegajo
    FROM descuentososunc
    NATURAL JOIN (
	 SELECT legajosiu,legajosiu as nrolegajo,nrodoc,tipodoc FROM afilisos
	  ) as t
    NATURAL JOIN (SELECT idcargo as nrocargo,legajosiu,tipodesig as tipoempleado FROM cargo ) as cargo
    LEFT JOIN infomeerrordescuentosplanilla USING(legajosiu,mesingreso,anioingreso)
    WHERE true
--     AND descuentososunc.mesingreso >= date_part('month', current_date -30)
     AND descuentososunc.mesingreso >= pmes
--     AND descuentososunc.anioingreso >= date_part('year', current_date - 30)     
     AND descuentososunc.anioingreso >= panio     
     AND (descuentososunc.nroconcepto = 388 or idconcepto=372 or descuentososunc.nroconcepto = 360 OR descuentososunc.nroconcepto = 387 OR descuentososunc.nroconcepto = 373 OR descuentososunc.nroconcepto = 374  )
    AND nullvalue(infomeerrordescuentosplanilla.legajosiu);

FETCH alta INTO elem;
WHILE  found LOOP
       SELECT INTO rinforme * FROM informedescuentoplanillav2
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
	    INSERT INTO cuentacorrientepagos(idcomprobantetipos,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,tipodoc,idctacte,idcentropago)
	    VALUES (13,CURRENT_DATE,concat ( 'Descuento SOSUNC liq ' , elem.nroliquidacion , ' cargo ' , elem.nrocargo , ' ' , elem.mesingreso , '/' , elem.anioingreso),10311,elem.importe*-1,currval('informedescuentoplanilla_idinforme_seq'),elem.importe*-1,elem.nroconcepto,elem.nrodoc,elem.tipodoc,elem.idctacte,centro());
      END IF;
fetch alta into elem;
END LOOP;
CLOSE alta;
/*Paso tambien ahora por parametro 1 si es descuento concepto de sosunc*/
--PERFORM asentarreciboenctactepagos(date_part('month', current_date -30)::integer,date_part('year', current_date - 30)::integer,1);
PERFORM asentarreciboenctactepagos(pmes,panio,1);

return resultado;

END;

$function$
