CREATE OR REPLACE FUNCTION public.agregaraportesaux2()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
Carga los aportes de las personas de la universidad, utilizando la informacion de las tablas
dh49 para la liquidacion y dh21 para los datos de los aportes

02-03-2015 Malapi, modifico para que tambien se ingresen los descuentos y generen los recibos automaticos. Llamo a la funcion agregardescuentosconceptos();
*/
DECLARE
	alta refcursor;
        cursorauxi refcursor;
        elemcursor record;

 	rliquidacion RECORD;
	rpersona RECORD;
 	rcargo RECORD;
 	raporte RECORD;
 	verifica RECORD;
	
        elem RECORD;
        infaporte RECORD;
 	con RECORD;
 	resultado boolean;
	resultado2 boolean;
	cargarrec boolean;
	
        tipinf varchar;
	nroinforme bigint;
        cuentac RECORD;
        rtaporterecibido RECORD;
	
BEGIN

ALTER TABLE aporte disable trigger amaporte;
ALTER TABLE concepto disable trigger amconcepto;
ALTER TABLE infaporrecibido disable trigger aminfaporrecibido;
ALTER TABLE  persona DISABLE TRIGGER ALL;
--ALTER TABLE persona disable trigger actualizaestadoconfechafinos;

 /*

SELECT INTO rtaporterecibido *  FROM taporterecibido
            WHERE  nullvalue(taporterecibido.mesingreso)
            OR  taporterecibido.mesingreso <> date_part('month', current_date -30)
            OR taporterecibido.anioingreso <> date_part('year', current_date -30);

IF FOUND THEN
-- Borro de taporterecibido, todo lo que no corresponda a este mes, por lo de los aportes de jubilados.
   DELETE FROM taporterecibido WHERE nullvalue(taporterecibido.mesingreso)
            OR  taporterecibido.mesingreso <> date_part('month', current_date -30)
            OR taporterecibido.anioingreso <> date_part('year', current_date -30);
END IF;
/*Verifico si las liquidaciones estan cargadas, sino las ingreso*/
OPEN cursorauxi FOR SELECT nroliquidacion,dh21.anioingreso as anio,dh21.mesingreso as mes
                    FROM dh21 NATURAL JOIN dh21proceso 
                    WHERE dh21.mesingreso >= date_part('month', current_date -30)
	                      AND dh21.anioingreso >= date_part('year', current_date - 30)
	                    /*  AND dh21.nroconcepto <> 372
	                      AND dh21.nroconcepto <> 387*/
                              AND tipoproceso ilike '%aporte%'                             
                           GROUP BY nroliquidacion,anioingreso,mesingreso;

FETCH cursorauxi INTO elemcursor;
WHILE found Loop
SELECT INTO rliquidacion * FROM liquidacion WHERE liquidacion.nroliquidacion = elemcursor.nroliquidacion;
IF NOT FOUND THEN
SELECT INTO rliquidacion
       max(dh49.mesliquidacion) as mes,
       cast(max(dh49.anioliquidacion) as bigint) as anio,
       sum(dh49.importebruto) as importebruto,
       count(dh49.nrocargo) as nrocargo
       FROM dh49 WHERE dh49.nroliquidacion = elemcursor.nroliquidacion
       GROUP BY nroliquidacion;
       IF FOUND THEN
       INSERT INTO liquidacion (codogpliq,nroliquidacion,denominacion,mes,fechaingreso,mtotalliq,cantotcarliq,idtipoliq,anio)
          VALUES(elemcursor.nroliquidacion,elemcursor.nroliquidacion,'Sueldo o SAC',CAST(elemcursor.mes as BIGINT),current_date,rliquidacion.importebruto,rliquidacion.nrocargo,'SUE',cast(elemcursor.anio as bigint));
       ELSE
        INSERT INTO liquidacion (codogpliq,nroliquidacion,denominacion,mes,fechaingreso,mtotalliq,cantotcarliq,idtipoliq,anio)
          VALUES(elemcursor.nroliquidacion,elemcursor.nroliquidacion,'Sueldo o SAC',CAST(elemcursor.mes as BIGINT),current_date,0,0,'SUE',cast(elemcursor.anio as bigint));

       END IF;
END IF;
/*El nroTipoInforme es el anio*100 + mes*/
SELECT INTO rliquidacion * FROM liquidacion WHERE liquidacion.nroliquidacion = elemcursor.nroliquidacion;
nroinforme = cast(rliquidacion.anio as integer) * 100 + cast(rliquidacion.mes as integer);

FETCH cursorauxi INTO elemcursor;
END LOOP;
CLOSE cursorauxi;

/*Verifico las personas que deben ser informadas*/
OPEN cursorauxi FOR SELECT legajosiu,nroliquidacion,nrocargo
                    FROM
                    (
                    SELECT nrolegajo as legajosiu,max(nroliquidacion) as nroliquidacion ,max(nrocargo) as nrocargo
                    FROM dh21  NATURAL JOIN dh21proceso 
                    WHERE dh21.mesingreso >= date_part('month', current_date -30)
	                      AND dh21.anioingreso >= date_part('year', current_date - 30)
	                      /*AND dh21.nroconcepto <> 372
	                      AND dh21.nroconcepto <> 387
                              */
                              AND tipoproceso ilike '%aporte%'
                          GROUP BY nrolegajo
                    ) as personas
                    LEFT JOIN (
                     SELECT legajosiu,nrodoc,tipodoc FROM afilidoc
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afilinodoc
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afiliauto
                      UNION
                      SELECT legajosiu,nrodoc,tipodoc FROM afilirecurprop
              /*KR 21-4-15 agregue a los afiliados de sosunc para usar el sp y procesar los aportes de los afil de sosunc*/
 
                      UNION
                      SELECT * FROM
                     (SELECT case when (elcargo.idcargo<990000) then 
                       (990000 +elcargo.idcargo::numeric)  else  elcargo.idcargo end  as nrolegajo,
                        ca.persona.penrodoc, ca.persona.idtipodocumento
                       FROM ca.empleado  NATURAL JOIN ca.persona JOIN ( SELECT nrodoc,tipodoc,MAX(idcargo)as idcargo,legajosiu		
                                                    FROM cargo WHERE fechainilab<= CURRENT_DATE 
                                                    and fechafinlab >=	CURRENT_DATE and iddepen='SOS'		
                                                    GROUP BY nrodoc,tipodoc,legajosiu		
                                                    ORDER BY nrodoc) as elcargo  
                               on (elcargo.tipodoc=idtipodocumento and elcargo.nrodoc=penrodoc) 
                           ) as losdesosunc     

                      ) as t
                      USING(legajosiu)
                     WHERE nullvalue(t.legajosiu);

FETCH cursorauxi INTO elemcursor;
WHILE found Loop
       --Reportarlo como que no existe en sosunc, para este tipo de informe en lugar de colocar la barra se coloca el DNI
       tipinf = 'NOEXISTE'; 		
       SELECT INTO resultado2 *
                       FROM agregareninforme(tipinf,CAST(nroinforme AS bigint),current_date,cast(elemcursor.nrocargo as bigint),cast(elemcursor.nroliquidacion as varchar),cast(elemcursor.legajosiu as varchar),cast(0 as smallint));
FETCH cursorauxi INTO elemcursor;
END LOOP;
CLOSE cursorauxi;

*/

resultado = true;
/*Ingreso los aportes de las personas que no fueron reportadas en el informe*/
OPEN alta FOR SELECT *
    FROM dh21 NATURAL JOIN dh21proceso 
NATURAL JOIN (
        
          SELECT * FROM
         (SELECT case when (elcargo.idcargo<990000) then (990000 +elcargo.idcargo::numeric)  else  elcargo.idcargo end  as nrolegajo,
             ca.persona.penrodoc as nrodoc, ca.persona.idtipodocumento as tipodoc
             FROM ca.empleado  NATURAL JOIN ca.persona JOIN ( SELECT nrodoc,tipodoc,MAX(idcargo)as idcargo,legajosiu		
                                                    FROM cargo WHERE fechainilab<= CURRENT_DATE 
                                                    and fechafinlab >=	CURRENT_DATE and iddepen='SOS'		
                                                    GROUP BY nrodoc,tipodoc,legajosiu		
                                                    ORDER BY nrodoc) as elcargo 
                                          on (elcargo.tipodoc=idtipodocumento and elcargo.nrodoc=penrodoc) 
          ) as losdesosunc    
          ) as t
    JOIN liquidacion ON (dh21.nroliquidacion = CAST(liquidacion.nroliquidacion AS INTEGER))
    LEFT JOIN (
    SELECT CAST(infaporrecibido.nrodoc as INTEGER) as nrolegajo
     FROM infaporrecibido
     WHERE infaporrecibido.fechmodificacion = CURRENT_DATE
    ) as infaporrecibido
    USING(nrolegajo)
    WHERE /*dh21.mesingreso /*>= date_part('month', current_date -60)*/=5
	AND dh21.anioingreso >= date_part('year', current_date - 30)*/
	/*AND dh21.nroconcepto <> 372
	AND dh21.nroconcepto <> 387
       */
	    dh21.nroconcepto=1248
        AND tipoproceso ilike '%aporte%'
	AND nullvalue(infaporrecibido.nrolegajo);
	
FETCH alta INTO elem;
WHILE  found LOOP
     
      SELECT INTO cuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'UNC';
    /*  SELECT INTO verifica * FROM aporte
             JOIN concepto USING(idlaboral,nroliquidacion,mes,ano)
             WHERE aporte.idcargo = elem.nrocargo
             AND concepto.nroliquidacion = elem.nroliquidacion
             AND aporte.ano = elem.anio
             AND aporte.mes = elem.mes
             AND concepto.idconcepto = elem.nroconcepto;

IF NOT FOUND THEN
      SELECT INTO raporte * FROM aporte WHERE idcargo = elem.nrocargo
                                        AND nroliquidacion = elem.nroliquidacion
                                        AND ano = elem.anio
                                        AND mes = elem.mes;
      IF NOT FOUND THEN
       */        INSERT INTO aporte (ano,automatica,fechaingreso,idcargo,idcertpers,idlaboral,idlic,idrecibo,idresolbe,idtipoliquidacion,importe,mes,nroliquidacion,nrocuentac)
               VALUES (elem.anio,true,current_date,elem.nrocargo,null,elem.nrocargo,null,null,null,elem.idtipoliq,elem.importe,elem.mes,elem.nroliquidacion,cuentac.nrocuentac);
           /*     INSERT INTO aporteestado(idaporte,aeobservacion,idestadotipo,aefechafin,idcentroregionaluso) VALUES(currval('aporte_idaporte_seq'::regclass),'Al ingresar aportes de la Facultad',1,now(),centro());
               INSERT INTO aporteestado(idaporte,aeobservacion,idestadotipo,aefechafin,idcentroregionaluso) VALUES(currval('aporte_idaporte_seq'::regclass),'Al ingresar aportes de de la Facultad',7,null,centro()); 
 
      ELSE
               UPDATE aporte SET importe = importe + elem.importe
                      WHERE idcargo = elem.nrocargo
                       AND nroliquidacion = elem.nroliquidacion
                       AND ano = elem.anio
                       AND mes = elem.mes;
      END IF;*/
   /*   SELECT INTO con * FROM concepto WHERE concepto.idlaboral = elem.nrocargo
                                 AND concepto.idconcepto = elem.nroconcepto
                                 AND concepto.nroliquidacion = elem.nroliquidacion
                                 AND concepto.mes = elem.mes
                                 AND concepto.ano = elem.anio;
      IF FOUND THEN
       UPDATE concepto SET importe = (con.importe + elem.importe)
       WHERE concepto.idlaboral = elem.nrocargo
             AND concepto.idconcepto = elem.nroconcepto
             AND concepto.nroliquidacion = elem.nroliquidacion
             AND concepto.mes = elem.mes
             AND concepto.ano = elem.anio;
       ELSE
           INSERT INTO concepto(nroliquidacion,idlaboral,idconcepto,importe,imputacion,mes,ano)
           VALUES (elem.nroliquidacion,elem.nrocargo,elem.nroconcepto,elem.importe,elem.detalle,elem.mes,elem.anio);
       END IF;
       SELECT INTO rpersona * FROM persona WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc;
       SELECT INTO cargarrec * FROM agregarentaporterecibido(rpersona.nrodoc,rpersona.barra,'Malapi');
      
ELSE /*Si el aporte ya existe, tengo que verificar si se trata de un aporte retroactivo*/
     IF elem.anioretroactivo <> 0 AND  elem.mesretroactivo <> 0 THEN
     -- Ahora que se que es retroactivo tengo que verificar que falte el aporte del mes retroactivo
        SELECT INTO verifica * FROM aporte
                             JOIN concepto USING(idlaboral,nroliquidacion)
                             WHERE aporte.idcargo = elem.nrocargo
                                   AND concepto.nroliquidacion = elem.nroliquidacion
                                   AND aporte.ano = elem.anioretroactivo
                                   AND aporte.mes = elem.mesretroactivo
                                   AND concepto.idconcepto = elem.nroconcepto;

          IF NOT FOUND THEN
             SELECT INTO raporte * FROM aporte WHERE idcargo = elem.nrocargo
                                        AND nroliquidacion = elem.nroliquidacion
                                        AND ano = elem.anioretroactivo
                                        AND mes = elem.mesretroactivo;
             IF NOT FOUND THEN
                    INSERT INTO aporte (ano,automatica,fechaingreso,idcargo,idcertpers,idlaboral,idlic,idrecibo,idresolbe,idtipoliquidacion,importe,mes,nroliquidacion,nrocuentac)
                    VALUES (elem.anioretroactivo,true,current_date,elem.nrocargo,null,elem.nrocargo,null,null,null,elem.idtipoliq,elem.importe,elem.mesretroactivo,elem.nroliquidacion,cuentac.nrocuentac);
                    
             ELSE
               UPDATE aporte SET importe = importe + elem.importe
                      WHERE idcargo = elem.nrocargo
                       AND nroliquidacion = elem.nroliquidacion
                       AND ano = elem.anioretroactivo
                       AND mes = elem.mesretroactivo;
             END IF;
             SELECT INTO con * FROM concepto WHERE concepto.idlaboral = elem.nrocargo
                                 AND concepto.idconcepto = elem.nroconcepto
                                 AND concepto.nroliquidacion = elem.nroliquidacion
                                 AND concepto.ano = elem.anioretroactivo
                                 AND concepto.mes = elem.mesretroactivo;
             IF FOUND THEN
                UPDATE concepto SET importe = (con.importe + elem.importe)
                WHERE concepto.idlaboral = elem.nrocargo
                      AND concepto.idconcepto = elem.nroconcepto
                      AND concepto.nroliquidacion = elem.nroliquidacion
                      AND concepto.ano = elem.anioretroactivo
                      AND concepto.mes = elem.mesretroactivo;
             ELSE
                 INSERT INTO concepto(nroliquidacion,idlaboral,idconcepto,importe,imputacion,mes,ano)
                 VALUES (elem.nroliquidacion,elem.nrocargo,elem.nroconcepto,elem.importe,elem.detalle,elem.mesretroactivo,elem.anioretroactivo);
             END IF;
          END IF;
     END IF;

END IF;*/
fetch alta into elem;
END LOOP;
CLOSE alta;

return resultado;
ALTER TABLE aporte enable trigger amaporte;
ALTER TABLE concepto enable trigger amconcepto;
ALTER TABLE infaporrecibido enable trigger aminfaporrecibido;

ALTER TABLE persona ENABLE TRIGGER ALL;
--ALTER TABLE persona enable trigger actualizaestadoconfechafinos;

END;
$function$
