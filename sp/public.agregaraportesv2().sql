CREATE OR REPLACE FUNCTION public.agregaraportesv2()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
Carga los aportes de las personas de la universidad, utilizando la informacion de las tablas
dh49 para la liquidacion y dh21 para los datos de los aportes
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
SELECT INTO rtaporterecibido *  FROM taporterecibido
            WHERE  nullvalue(taporterecibido.mesingreso)
            OR  taporterecibido.mesingreso <> date_part('month', current_date -30)
            OR taporterecibido.anioingreso <> 2009;

IF FOUND THEN
-- Borro de taporterecibido, todo lo que no corresponda a este mes, por lo de los aportes de jubilados.
   DELETE FROM taporterecibido WHERE nullvalue(taporterecibido.mesingreso)
            OR  taporterecibido.mesingreso <> date_part('month', current_date -30)
            OR taporterecibido.anioingreso <> 2009;
END IF;
/*Verifico si las liquidaciones estan cargadas, sino las ingreso*/
OPEN cursorauxi FOR SELECT nroliquidacion
                    FROM dh21
                    WHERE dh21.mesingreso >= date_part('month', current_date -30)
	                      AND dh21.anioingreso >= 2009
	                      AND dh21.nroconcepto <> 372
	                      AND dh21.nroconcepto <> 387
	                     AND dh21.nrolegajo = 205961
                          GROUP BY nroliquidacion;

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
       INSERT INTO liquidacion (codogpliq,nroliquidacion,denominacion,mes,fechaingreso,mtotalliq,cantotcarliq,idtipoliq,anio)
          VALUES(elemcursor.nroliquidacion,elemcursor.nroliquidacion,'Sueldo o SAC',CAST(rliquidacion.mes as BIGINT),current_date,rliquidacion.importebruto,rliquidacion.nrocargo,'SUE',cast(rliquidacion.anio as bigint));

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
                    FROM dh21
                    WHERE dh21.mesingreso >= date_part('month', current_date -30)
	                      AND dh21.anioingreso >= 2009
	                      AND dh21.nroconcepto <> 372
	                      AND dh21.nroconcepto <> 387
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

resultado = true;
/*Ingreso los aportes de las personas que no fueron reportadas en el informe*/
OPEN alta FOR SELECT *
    FROM dh21
NATURAL JOIN (
         SELECT legajosiu as nrolegajo,nrodoc,tipodoc FROM afilidoc
         UNION
         SELECT legajosiu as nrolegajo,nrodoc,tipodoc FROM afilinodoc
         UNION
         SELECT legajosiu as nrolegajo,nrodoc,tipodoc FROM afiliauto
         UNION
         SELECT legajosiu as nrolegajo,nrodoc,tipodoc FROM afilirecurprop
          ) as t
    JOIN liquidacion ON (dh21.nroliquidacion = CAST(liquidacion.nroliquidacion AS INTEGER))
    LEFT JOIN (
    SELECT CAST(infaporrecibido.nrodoc as INTEGER) as nrolegajo
     FROM infaporrecibido
     WHERE infaporrecibido.fechmodificacion = CURRENT_DATE
    ) as infaporrecibido
    USING(nrolegajo)
    WHERE dh21.mesingreso >= date_part('month', current_date -30)
	AND dh21.anioingreso >= 2009
	AND dh21.nroconcepto <> 372
	AND dh21.nroconcepto <> 387
--	AND dh21.nroconcepto = 60
	--AND dh21.nroliquidacion >= 327
	--AND  dh21.nroconcepto <> 311
	AND dh21.nrolegajo = 205961;
    --AND nullvalue(infaporrecibido.nrolegajo);
	
FETCH alta INTO elem;
WHILE  found LOOP
      SELECT INTO cuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'UNC';
      SELECT INTO verifica * FROM aporte
             JOIN concepto USING(idlaboral,nroliquidacion)
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
               INSERT INTO aporte (ano,automatica,fechaingreso,idcargo,idcertpers,idlaboral,idlic,idrecibo,idresolbe,idtipoliquidacion,importe,mes,nroliquidacion,nrocuentac)
               VALUES (elem.anio,true,current_date,elem.nrocargo,null,elem.nrocargo,null,null,null,elem.idtipoliq,elem.importe,elem.mes,elem.nroliquidacion,cuentac.nrocuentac);

      ELSE
               UPDATE aporte SET importe = importe + elem.importe
                      WHERE idcargo = elem.nrocargo
                       AND nroliquidacion = elem.nroliquidacion
                       AND ano = elem.anio
                       AND mes = elem.mes;
      END IF;
      SELECT INTO con * FROM concepto WHERE concepto.idlaboral = elem.nrocargo
                                 AND concepto.idconcepto = elem.nroconcepto
                                 AND concepto.nroliquidacion = elem.nroliquidacion;
      IF FOUND THEN
       UPDATE concepto SET importe = (con.importe + elem.importe)
       WHERE concepto.idlaboral = elem.nrocargo
             AND concepto.idconcepto = elem.nroconcepto
             AND concepto.nroliquidacion = elem.nroliquidacion;
       ELSE
           INSERT INTO concepto(nroliquidacion,idlaboral,idconcepto,importe,imputacion)
           VALUES (elem.nroliquidacion,elem.nrocargo,elem.nroconcepto,elem.importe,elem.detalle);
       END IF;
       SELECT INTO rpersona * FROM persona WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc;
       SELECT INTO cargarrec * FROM agregarentaporterecibido(rpersona.nrodoc,rpersona.barra,'Malapi');

       SELECT INTO rcargo * FROM cargo WHERE cargo.idcargo = elem.nrocargo;
       IF(rpersona.fechafinos <= rcargo.fechafinlab + INTEGER '90') THEN
            UPDATE persona SET fechafinos = rcargo.fechafinlab + INTEGER '90'
               WHERE nrodoc = rpersona.nrodoc and tipodoc = rpersona.tipodoc;
       END IF;
END IF;
fetch alta into elem;
END LOOP;
CLOSE alta;
return resultado;
ALTER TABLE aporte enable trigger amaporte;
ALTER TABLE concepto enable trigger amconcepto;
ALTER TABLE infaporrecibido enable trigger aminfaporrecibido;

END;
$function$
