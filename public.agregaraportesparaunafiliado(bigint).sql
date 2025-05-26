CREATE OR REPLACE FUNCTION public.agregaraportesparaunafiliado(bigint)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
Carga los aportes  correspondientes a una persona de la unc cuyo numero de legajo se recibe por parametro,
utilizando la informacion de las tablas dh49 para la liquidacion y dh21 para los datos de los aportes
*/
 /* Recordar llamar a SELECT * FROM cambiarestadoconfechafinos('persona.nrodoc = ? and persona.tipodoc = ?');
      para el cambio de estado */
DECLARE
	alta refcursor;
	cursorauxi refcursor;
	elemcursor record;

	rliquidacion RECORD;
	rpersona RECORD;
	rcargo RECORD;
	raporte RECORD;
	verifica RECORD;
	esbecario RECORD;
	elem RECORD;
	con RECORD;
	resultado boolean;
	resultado2 boolean;
	cargarrec boolean;
	idresolbec INTEGER;
	
    tipinf varchar;
	nroinforme bigint;
    cuentac RECORD;
    rtaporterecibido RECORD;
	
BEGIN
idresolbec =NULL;
/*Verifico si las liquidaciones estan cargadas, sino las ingreso*/
OPEN cursorauxi FOR SELECT nroliquidacion,dh21.anioingreso as anio,dh21.mesingreso as mes
                    FROM dh21
/*09-04-2010 MLP : Modifico, para que cargue todo los aportes retroactivos disponibles en la tabla dh21,
pues se usa este sp para cargar aportes retroactivos.*/

                    WHERE /*dh21.mesingreso >= date_part('month', current_date -30)
	                      AND dh21.anioingreso >= date_part('year', current_date - 30)
	                      AND*/ dh21.nroconcepto <> 372
	                      AND dh21.nroconcepto <> 387
	                      AND dh21.nrolegajo = $1
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
         UNION
         SELECT idresolbe as nrolegajo, nrodoc, tipodoc
         FROM afilibec NATURAL JOIN persona NATURAL JOIN resolbec
          UNION
          SELECT * FROM
         (SELECT case when (elcargo.idcargo<990000) then (990000 +elcargo.idcargo::numeric)  else  elcargo.idcargo end  as nrolegajo,
             ca.persona.penrodoc, ca.persona.idtipodocumento
             FROM ca.empleado  NATURAL JOIN ca.persona JOIN ( SELECT nrodoc,tipodoc,MAX(idcargo)as idcargo,legajosiu		
                                                    FROM cargo WHERE fechainilab<= CURRENT_DATE 
                                                    and fechafinlab >=	CURRENT_DATE and iddepen='SOS'		
                                                    GROUP BY nrodoc,tipodoc,legajosiu		
                                                    ORDER BY nrodoc) as elcargo 
                                          on (elcargo.tipodoc=idtipodocumento and elcargo.nrodoc=penrodoc) 
          ) as losdesosunc          

		
          ) as t
NATURAL JOIN persona
/*09-04-2010 MLP : Modifico, para que cargue todo los aportes retroactivos disponibles en la tabla dh21,
pues se usa este sp para cargar aportes retroactivos. */
    JOIN liquidacion ON (dh21.nroliquidacion = CAST(liquidacion.nroliquidacion AS INTEGER))
    WHERE 

/*dh21.mesingreso >= date_part('month', current_date -30)
	AND dh21.anioingreso >= date_part('year', current_date - 30)
	AND */ 
        
dh21.nroconcepto <> 372
	AND dh21.nroconcepto <> 387
	AND dh21.nrolegajo = $1;
	
FETCH alta INTO elem;
WHILE  found LOOP
      SELECT INTO cuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'UNC';
      SELECT INTO verifica * FROM aporte
             JOIN concepto USING(idlaboral,nroliquidacion,mes,ano)
             WHERE aporte.idcargo = elem.nrocargo
             AND concepto.nroliquidacion = elem.nroliquidacion
             AND aporte.ano = elem.anio
             AND aporte.mes = elem.mes
             AND concepto.idconcepto = elem.nroconcepto;

IF NOT FOUND THEN

      SELECT INTO esbecario * FROM afilibec
      WHERE afilibec.nrodoc= elem.nrodoc AND afilibec.tipodoc= elem.tipodoc AND elem.barra = 34;
      IF FOUND THEN
         /*Malapi 03-01-2011 Cuando se trata de un Becario el IdLaboral el el IdREolBe ademas de campo Idresolbe diferente de null*/
         SELECT INTO raporte * FROM aporte WHERE idlaboral = esbecario.idresolbe
                                        AND nroliquidacion = elem.nroliquidacion
                                        AND ano = elem.anio
                                        AND mes = elem.mes;


      IF NOT FOUND THEN
               INSERT INTO aporte (ano,automatica,fechaingreso,idcargo,idcertpers,idlaboral,idlic,idrecibo,idresolbe,idtipoliquidacion,importe,mes,nroliquidacion,nrocuentac)
               VALUES (elem.anio,true,current_date,null,null,esbecario.idresolbe,null,null,esbecario.idresolbe,elem.idtipoliq,elem.importe,elem.mes,elem.nroliquidacion,cuentac.nrocuentac);


        INSERT INTO aporteestado(idaporte,aeobservacion,idestadotipo,aefechafin,idcentroregionaluso) VALUES(currval('aporte_idaporte_seq'::regclass),'Al ingresar aportes de la Facultad',1,now(),centro());
               INSERT INTO aporteestado(idaporte,aeobservacion,idestadotipo,aefechafin,idcentroregionaluso) VALUES(currval('aporte_idaporte_seq'::regclass),'Al ingresar aportes de de la Facultad',7,null,centro()); 
 

      ELSE
               UPDATE aporte SET importe =  importe+elem.importe
                      WHERE idlaboral = esbecario.idresolbe
                       AND nroliquidacion = elem.nroliquidacion
                       AND ano = elem.anio
                       AND mes = elem.mes;
      END IF;
      SELECT INTO con * FROM concepto WHERE concepto.idlaboral = esbecario.idresolbe
                                 AND concepto.idconcepto = elem.nroconcepto
                                 AND concepto.nroliquidacion = elem.nroliquidacion
                                 AND ano = elem.anio  AND mes = elem.mes;
      IF FOUND THEN
       UPDATE concepto SET importe =  elem.importe

       WHERE concepto.idlaboral = esbecario.idresolbe
             AND concepto.idconcepto = elem.nroconcepto
             AND concepto.nroliquidacion = elem.nroliquidacion  AND ano = elem.anio AND mes = elem.mes;
       ELSE
           INSERT INTO concepto(nroliquidacion,idlaboral,idconcepto,importe,imputacion, mes, ano)
           VALUES (elem.nroliquidacion,esbecario.idresolbe,elem.nroconcepto,elem.importe,elem.detalle, elem.mes, elem.anio);
       END IF;

         
         
         
      ELSE
      
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
                                 AND concepto.nroliquidacion = elem.nroliquidacion AND ano = elem.anio AND mes = elem.mes;
      IF FOUND THEN
       UPDATE concepto SET importe =(con.importe + elem.importe)

       WHERE concepto.idlaboral = elem.nrocargo
             AND concepto.idconcepto = elem.nroconcepto
             AND concepto.nroliquidacion = elem.nroliquidacion  AND ano = elem.anio AND mes = elem.mes;
       ELSE
           INSERT INTO concepto(nroliquidacion,idlaboral,idconcepto,importe,imputacion, mes, ano)
           VALUES (elem.nroliquidacion,elem.nrocargo,elem.nroconcepto,elem.importe,elem.detalle, elem.mes, elem.anio);
       END IF;

      END IF;

      SELECT INTO rpersona * FROM persona WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc;
       SELECT INTO cargarrec * FROM agregarentaporterecibido(rpersona.nrodoc,rpersona.barra,'Malapi');

      /* 09-04-2010 M.L.P Se llama desde la aplicacion, cuando esta todo cargado, Designaciones y Aportes
      Recordar llamar a SELECT * FROM cambiarestadoconfechafinos('persona.nrodoc = ? and persona.tipodoc = ?');
      para el cambio de estado */
END IF;
fetch alta into elem;
END LOOP;
CLOSE alta;
return resultado;

END;
$function$
