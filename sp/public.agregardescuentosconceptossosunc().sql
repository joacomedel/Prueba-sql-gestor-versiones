CREATE OR REPLACE FUNCTION public.agregardescuentosconceptossosunc()
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
    datocliente  record;
    datoverificaafil record;
    rinforme RECORD;
resultado boolean;
BEGIN

/*CREATE TEMP TABLE descuentososunc (	mesingreso INTEGER,	anioingreso INTEGER,	nroliquidacion INTEGER,	legajosiu INTEGER,	nrocargo INTEGER,	nroconcepto INTEGER,	importe NUMERIC(10,2),	tipodoc INTEGER,	nrodoc VARCHAR	) WITHOUT OIDS;
INSERT INTO descuentososunc VALUES (7,2016,516,990112,990112,387,757.36,1,'27091730');
*/

DELETE FROM infomeerrordescuentosplanilla;
/*Verifico las personas que deben ser informadas*/
OPEN cursorauxi FOR SELECT  legajosiu,nroliquidacion,nrocargo,importe,mesingreso,anioingreso
                    FROM  (
                    		SELECT max(descuentososunc.mesingreso) as mesingreso,max(descuentososunc.anioingreso) as anioingreso,legajosiu as legajosiu,max(nroliquidacion) as nroliquidacion ,max(nrocargo) as nrocargo,sum(importe) as importe
                    		FROM descuentososunc
                    		WHERE  descuentososunc.mesingreso >= date_part('month', current_date -30) AND descuentososunc.anioingreso >= date_part('year', current_date - 30)
               --     WHERE  descuentososunc.mesingreso >= 7 AND descuentososunc.anioingreso >= 2019
--KR 08-06-22 Daba error la consulta, se ve que se agrego el concepto 388 pero se nombraba mal al campo, como idconcepto
                     				AND (descuentososunc.nroconcepto = 372 OR descuentososunc.nroconcepto=388 OR descuentososunc.nroconcepto = 387 or  descuentososunc.nroconcepto = 373 or  descuentososunc.nroconcepto = 374)
                          	GROUP BY legajosiu
                    ) as personas
                    LEFT JOIN (
                      		SELECT legajosiu,nrodoc,tipodoc 
						    FROM afilisos
                      		UNION /*Dani agrego la union el 20220418 para incluir el personal de farmacia*/
                      		SELECT  emlegajo::bigint as legajosiu , penrodoc as nrodoc , idtipodocumento as tipodoc
                        	FROM ca.persona natural join ca.empleado
                      ) as t  USING(legajosiu)
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
OPEN alta FOR SELECT descuentososunc.*,nrodoc,tipodoc
                     ,CASE WHEN (idliquidaciontipo=1) THEN 'SOS' 
	             		   WHEN (idliquidaciontipo=2) THEN 'Farmacia' END  tipoempleado
					 ,nrodoc::integer * 10 + tipodoc as idctacte,legajosiu as nrolegajo
    		  FROM descuentososunc
    		  JOIN ca.liquidacion ON (nroliquidacion = idliquidacion)

 /* comenta vas 290823
En esta instancia se deben procesar los descuentos que no estan informados como error en infomeerrordescuentosplanilla
 NATURAL JOIN (
         SELECT legajosiu,legajosiu as nrolegajo,nrodoc,tipodoc FROM afilisos
          UNION /*KR 22-08-22 Agrego aqui tbn la union que Dani puso el 20220418*/
         SELECT emlegajo::bigint as legajosiu ,emlegajo::bigint as legajosiu , penrodoc as nrodoc , idtipodocumento as tipodoc
           FROM ca.persona natural join ca.empleado
          ) as t
    NATURAL JOIN (SELECT idcargo as nrocargo,legajosiu,tipodesig as tipoempleado FROM cargo 
                 UNION /*KR 22-08-22 Agrego aqui tbn la union que Dani puso en sp procesardescuentos_empleados_sosunc*/
                  SELECT  0 as idcargo,emlegajo::bigint  as legajosiu, 'Farmacia' tipoempleado
		    FROM ca.persona natural join ca.empleado natural join ca.categoriaempleado natural join ca.grupoliquidacionempleado
                    LEFT JOIN persona p ON (penrodoc =nrodoc and 	idtipodocumento= tipodoc)
		    WHERE   idcategoriatipo=1 and (idgrupoliquidaciontipo=2   or p.barra=35 )
                    and   (nullvalue(cefechafin) or cefechafin >=to_timestamp(concat(extract (year from current_date),'-',extract (month from current_date),'-1') ,'YYYY-MM-DD')::date)
               ) as cargo 

*/ 
    		LEFT JOIN infomeerrordescuentosplanilla USING(legajosiu,mesingreso,anioingreso)
    		WHERE true
     			  AND descuentososunc.mesingreso >= date_part('month', current_date -30)
   					--  AND descuentososunc.mesingreso >= 7
     			  AND descuentososunc.anioingreso >= date_part('year', current_date - 30)     
  					--   AND descuentososunc.anioingreso >= 2019     
     			  AND (descuentososunc.nroconcepto = 372 OR descuentososunc.nroconcepto=388 or descuentososunc.nroconcepto = 360 OR descuentososunc.nroconcepto = 387 OR descuentososunc.nroconcepto = 373 OR descuentososunc.nroconcepto = 374 )
    			  AND nullvalue(infomeerrordescuentosplanilla.legajosiu);

FETCH alta INTO elem;
WHILE  found LOOP
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
        
				/*   COMENTA VAS 300823 SELECT into datoverificaafil * 
				from ca.empleado 
				natural join ca.persona 
				natural join ca.categoriaempleado 
				natural join ca.grupoliquidacionempleado                
				LEFT JOIN persona p ON (penrodoc =nrodoc and 	idtipodocumento= tipodoc)
				where penrodoc=elem.nrodoc and   
 --KR 22-08-22 corrigo pq desde julio 2022 lozano es empleada de sosunc pero tiene cta cte como adherente, se le desconto en los haberes de junio y no se proceso pq en julio ya no era empleada de farmacia, y tiene los 3 meses de carencia

  						idcategoriatipo=1 and (idgrupoliquidaciontipo=2   or p.barra=35 )
                    	and   (nullvalue(cefechafin) or cefechafin >=to_timestamp(concat(extract (year from current_date),'-',extract (month from current_date),'-1') ,'YYYY-MM-DD')::date) ;
         
		 if not found then 
		 */
		 IF( elem.tipoempleado = 'SOS') THEN
--KR 06-12-22 TKT 5490 REClasificamos a 10201 para afiliados
           		INSERT INTO cuentacorrientepagos(idcomprobantetipos,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,tipodoc,idctacte,idcentropago)
           		VALUES (13,CURRENT_DATE,concat ( 'Descuento SOSUNC liq ' , elem.nroliquidacion , ' cargo ' , elem.nrocargo , ' ' , elem.mesingreso , '/' , elem.anioingreso),10201,elem.importe*-1,currval('informedescuentoplanilla_idinforme_seq'),elem.importe*-1,elem.nroconcepto,elem.nrodoc,elem.tipodoc,elem.idctacte,centro());

         ELSE /*quiere decir que encontro que era para aplicar a un empleado de farmacia*/

/*Dani agrego el 20220418 para que inserte en ctactepagocliente para el caso del personal de farmacia*/
           		SELECT INTO  datocliente * from clientectacte natural join cliente where nrocliente=elem.nrodoc;

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
PERFORM asentarreciboenctactepagos(date_part('month', current_date -30)::integer,date_part('year', current_date - 30)::integer,1);
--PERFORM asentarreciboenctactepagos(7,2019,1);

return resultado;

END;$function$
