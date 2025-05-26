CREATE OR REPLACE FUNCTION public.agregardescuentosconceptossosuncempfarmacia(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$--para solucionar el tk 4545 setear con 60 dias y legajo=20
DECLARE
    alta refcursor;
    cursorauxi refcursor;
    elemcursor record;
    elem RECORD;
    rinforme RECORD;
    rinformectactepago  record;
    resultado boolean;

BEGIN

/*CREATE TEMP TABLE descuentososunc (	mesingreso INTEGER,	anioingreso INTEGER,	nroliquidacion INTEGER,	legajosiu INTEGER,	nrocargo INTEGER,	nroconcepto INTEGER,	importe NUMERIC(10,2),	tipodoc INTEGER,	nrodoc VARCHAR	) WITHOUT OIDS;
INSERT INTO descuentososunc VALUES (9,2021,747,20,20,387,7837.64,1,'32037023');
DAniela Torres, emlegajo=20
*/

DELETE FROM infomeerrordescuentosplanilla;
/*Verifico las personas que deben ser informadas*/
OPEN cursorauxi FOR SELECT
                legajosiu,nroliquidacion,nrocargo,importe,mesingreso,anioingreso
                    FROM
                    (
                    SELECT max(descuentososunc.mesingreso) as mesingreso,max(descuentososunc.anioingreso) as anioingreso,legajosiu as legajosiu,max(nroliquidacion) as nroliquidacion ,max(nrocargo) as nrocargo,sum(importe) as importe
                    FROM descuentososunc
                    WHERE 
    descuentososunc.mesingreso >= date_part('month', current_date -30) AND descuentososunc.anioingreso >= date_part('year', current_date -30)
            
                     AND (descuentososunc.nroconcepto = 372 OR descuentososunc.nroconcepto=388 OR descuentososunc.nroconcepto = 387 or  descuentososunc.nroconcepto = 373 or  descuentososunc.nroconcepto = 374) 
--and legajosiu=2 
                          GROUP BY legajosiu
                    ) as personas
            
                     WHERE nullvalue(legajosiu);
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
OPEN alta FOR SELECT descuentososunc.*,nrodoc,tipodoc,'null' as tipoempleado,nrodoc::integer * 10 + tipodoc as idctacte,t.nrolegajo,t.idclientectacte,t.idcentroclientectacte
    FROM descuentososunc
     NATURAL JOIN (
         SELECT ca.empleado.emlegajo::integer as legajosiu,ca.empleado.emlegajo::integer as nrolegajo,
    ca.persona.penrodoc  as nrodoc,ca.persona.idtipodocumento as tipodoc ,idclientectacte,idcentroclientectacte
    FROM ca.persona natural join ca.empleado
    join cliente on(nrocliente=penrodoc and cliente.barra=idtipodocumento ) 
    join clientectacte on(cliente.nrocliente=clientectacte.nrocliente and cliente.barra=clientectacte.barra)
          ) as t
  --  NATURAL JOIN (SELECT idcargo as nrocargo,legajosiu,tipodesig as tipoempleado FROM cargo ) as cargo
     LEFT JOIN infomeerrordescuentosplanilla USING(legajosiu,mesingreso,anioingreso)
    WHERE true
  AND descuentososunc.mesingreso >= date_part('month', current_date -30)
    
     AND descuentososunc.anioingreso >= date_part('year', current_date - 30)  
     
  --and legajosiu=2 
     AND (descuentososunc.nroconcepto = 372 OR descuentososunc.nroconcepto=388  or descuentososunc.nroconcepto = 360 OR descuentososunc.nroconcepto = 387 OR descuentososunc.nroconcepto = 373 OR descuentososunc.nroconcepto = 374 )
    AND nullvalue(infomeerrordescuentosplanilla.legajosiu);

FETCH alta INTO elem;
WHILE  found LOOP
       SELECT INTO rinforme * FROM informedescuentoplanillav2
                            WHERE nroliquidacion = elem.nroliquidacion
                            AND idcargo = elem.nrocargo
                            AND importe = elem.importe
                            AND mes = elem.mesingreso
                            AND anio = elem.anioingreso
                                    AND concepto =elem.nroconcepto ;
--and idcargo=2 ;
       IF NOT FOUND THEN
              INSERT INTO informedescuentoplanillav2
                     (idinforme,informedescuentoplanillatipo,nroliquidacion,legajosiu,concepto,idcargo,importe,fechaingreso,mes,anio,tipoempleado,importeimputado,nrodoc,tipodoc)
            VALUES (nextval('informedescuentoplanilla_idinforme_seq'),2,elem.nroliquidacion,elem.nrolegajo,elem.nroconcepto,elem.nrocargo,elem.importe,CURRENT_DATE,elem.mesingreso,elem.anioingreso,elem.tipoempleado,elem.importe,elem.nrodoc,elem.tipodoc);
      
end if;
    /*  INSERT INTO cuentacorrientepagos(idcomprobantetipos,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idconcepto,nrodoc,tipodoc,idctacte,idcentropago)
            VALUES (13,CURRENT_DATE,concat ( 'Descuento SOSUNC liq ' , elem.nroliquidacion , ' cargo ' , elem.nrocargo , ' ' , elem.mesingreso , '/' , elem.anioingreso),10311,elem.importe*-1,currval('informedescuentoplanilla_idinforme_seq'),elem.importe*-1,elem.nroconcepto,elem.nrodoc,elem.tipodoc,elem.idctacte,centro());
   */
 SELECT INTO rinformectactepago * FROM ctactepagocliente  
                            WHERE idclientectacte=elem.idclientectacte 
                                 and idcentroclientectacte=elem.idcentroclientectacte 
                                 and importe = elem.importe;
                                -- AND mes = elem.mesingreso
                               --  AND anio = elem.anioingreso
                               -- and idclientectacte =764 and idcentroclientectacte =1;
 IF NOT FOUND THEN
--KR 06-07-22 se modifica el nrocuentac a la que va el movimiento, Deudores por Asistencial Farmacia  // antes 10311
 INSERT INTO ctactepagocliente(idcomprobantetipos,fechamovimiento,movconcepto,nrocuentac,importe,idcomprobante,saldo,idclientectacte,idcentroclientectacte,idcentropago)
            VALUES (13,CURRENT_DATE,concat ( 'Descuento SOSUNC liq ' , elem.nroliquidacion , ' cargo ' , elem.nrocargo , ' ' ),
10814,elem.importe*-1,currval('informedescuentoplanilla_idinforme_seq'),elem.importe*-1,elem.idclientectacte,elem.idcentroclientectacte,centro());

      END IF;
fetch alta into elem;
END LOOP;
CLOSE alta;

 
 PERFORM asentarreciboenctactepagosfarmacia(date_part('month', current_date -30)::integer,date_part('year', current_date - 30)::integer,1);
   
return resultado;

END;$function$
