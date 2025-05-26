CREATE OR REPLACE FUNCTION public.agregaraportes(character varying, character varying, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*agregaraportes" ('Malapi','SAC',3,2006)
$1 Usuario
$2 TipoLiquidacion
$3 Mes
$4 AÃ±o
*/
DECLARE
	alta CURSOR FOR SELECT * FROM tcargaaporte ORDER BY tcargaaporte.nrodoc,tcargaaporte.tipodoc;
	usuario alias for $1;
	tipoliquidacion alias for $2;
    mesLiq alias for $3;
	anio alias for $4;
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	estaeninforme RECORD;
	laboral RECORD;
	aux2 RECORD;
	con RECORD;
	td record;
	rpersona RECORD;
	rcargo RECORD;
	nrodocanterior varchar;
	tipodocanterior integer;
	numcargo integer;
	idcert integer;
	lic integer;
	reci integer;
	resol integer;
	fechaini date;
	fechafin date;
	resultado boolean;
	resultado2 boolean;
	cargarrec boolean;
	tdoc integer;
	barraEmp smallint;
	tipinf varchar;
	nroinforme bigint;
    cuentac RECORD;
	r boolean;
BEGIN
ALTER TABLE aporte disable trigger amaporte;
ALTER TABLE concepto disable trigger amconcepto;
ALTER TABLE infaporrecibido disable trigger aminfaporrecibido;

nrodocanterior = '';
tipodocanterior = 0;
resultado = true;
OPEN alta;
FETCH alta INTO elem;
WHILE  found LOOP
/*El nroTipoInforme es el anio*100 + mes*/
nroinforme = elem.anio * 100 + elem.mes;
Select INTO td *  from tiposdoc where descrip = elem.tipodoc;
tdoc=td.tipodoc;
       IF (nrodocanterior <> elem.nrodoc OR tipodocanterior <> tdoc ) THEN
           nrodocanterior = elem.nrodoc;
           tipodocanterior = tdoc;
           	SELECT INTO aux * FROM persona WHERE persona.nrodoc = elem.nrodoc AND persona.tipodoc = tdoc;
 	        if NOT FOUND THEN
 		       /*Reportarlo como que no existe en sosunc, para este tipo de informe en lugar de colocar la barra se coloca el DNI*/
                tipinf = 'NOEXISTE'; 		
                SELECT INTO resultado2 *
                       FROM agregareninforme(tipinf,CAST(nroinforme AS bigint),current_date,elem.idlaboral,elem.nroliq,elem.nrodoc,CAST(tdoc AS smallint ));
  		    ELSE
 		      /*Si esxite buscar su fecha de inicio y fin laboral*/
 		      barraEmp = aux.barra;
                IF elem.tipoemp = 'BECARIO' THEN
                  SELECT INTO laboral *
                         FROM resolbec natural join afilibec
                         WHERE afilibec.nrodoc = elem.nrodoc AND afilibec.tipodoc = tdoc; 	   		
                  IF NOT FOUND THEN
                            /*Reporterlo como que no existe la resolucion*/
                      tipinf = 'NOEXISTELABORAL'; 	
                      SELECT INTO resultado2 * FROM agregareninforme(tipinf,CAST(nroinforme AS bigint),current_date,elem.idlaboral,elem.nroliq,elem.nrodoc,CAST(barraEmp AS smallint ));
                  ELSE /* IF NOT FOUND FROM resolbec*/
                      resol = laboral.idreslbe;
                      fechaini = laboral.fechainilab;
                      fechafin = laboral.fechafinlab;
                  END IF; /* IF NOT FOUND FROM resolbec*/
                ELSE /* IF elem.tipoemp = 'BECARIO' THEN */
                   SELECT INTO laboral *
                          FROM cargo
                          WHERE  cargo.idcargo = elem.idlaboral
                                 AND cargo.nrodoc = elem.nrodoc
                                 AND cargo.tipodoc = tdoc; 	   		
                   IF NOT FOUND THEN
                                /*Reporterlo como que no existe el cargo*/
                       tipinf = 'NOEXISTELABORAL';
                       SELECT INTO resultado2 * FROM agregareninforme(tipinf,CAST(nroinforme AS bigint),current_date,elem.idlaboral,elem.nroliq,elem.nrodoc,CAST(barraEmp AS smallint ));
                                /*Lo busco para ver si se ingreso en el informe de aportes recibidos*/
                   ELSE /*IF NOT FOUND FROM cargo*/
                        numcargo = laboral.idcargo;
                        fechaini = laboral.fechainilab;
                        fechafin = laboral.fechafinlab;
                   END IF;
                END IF; /* IF elem.tipoemp = 'BECARIO'*/
                SELECT INTO estaeninforme *
                       from infaporrecibido
                       where infaporrecibido.nrodoc = elem.nrodoc
                             AND infaporrecibido.fechmodificacion = CURRENT_DATE
                             AND infaporrecibido.nroliquidacion = elem.nroliq;

                IF NOT found THEN
                       --SELECT INTO resultado * FROM --cambiarestado(true,fechaini,fechafin,CAST(elem.idlaboral AS --integer),elem.nroliq,elem.nrodoc,tdoc);
                       SELECT INTO cuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'UNC';
                       INSERT INTO aporte (ano,automatica,fechaingreso,idcargo,idcertpers,idlaboral,idlic,idrecibo,idresolbe,idtipoliquidacion,importe,mes,nroliquidacion,nrocuentac)
                                           VALUES (elem.anio,true,current_date,numcargo,idcert,elem.idlaboral,lic,reci,resol,tipoliquidacion,elem.importe,elem.mes,elem.nroliq,cuentac.nrocuentac);
                       INSERT INTO concepto (nroliquidacion,idlaboral,idconcepto,importe,imputacion,ano,mes)
                                           VALUES (elem.nroliq,elem.idlaboral,elem.tipoconcepto,elem.importe,'',elem.anio,elem.mes);

                       SELECT INTO cargarrec * FROM agregarentaporterecibido(aux.nrodoc,aux.barra,usuario);
                END IF;
            END IF; /*NOT FOUND THEN FROM afilsosunc*/
          ELSE /*IF (nrodocanterior <> elem.nrodoc AND tipodocanterior <> tipodoc )*/
                /*Ya se analizo el tipo y numero de documento*/
            /*Lo busco para ver si se ingreso en el informe de aportes recibidos*/
          SELECT INTO estaeninforme * from infaporrecibido where elem.nrodoc = infaporrecibido.nrodoc
                                                       AND infaporrecibido.fechmodificacion = CURRENT_DATE
                                                       AND infaporrecibido.nroliquidacion = elem.nroliq;
             IF NOT found then
                     SELECT INTO cuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'UNC';
                     INSERT INTO aporte (ano,automatica,fechaingreso,idcargo,idcertpers,idlaboral,idlic,idrecibo,idresolbe,idtipoliquidacion,importe,mes,nroliquidacion,nrocuentac)
                                 VALUES (elem.anio,true,current_date,numcargo,idcert,elem.idlaboral,lic,reci,resol,tipoliquidacion,elem.importe,elem.mes,elem.nroliq,cuentac.nrocuentac);
                     SELECT INTO con * FROM concepto WHERE concepto.idlaboral = elem.idlaboral
                                 AND concepto.idconcepto = elem.tipoconcepto
                                 AND concepto.nroliquidacion = elem.nroliq
                                 AND concepto.mes = elem.mes
                                 AND concepto.ano = elem.anio;
                                 IF FOUND THEN
                                 UPDATE concepto SET importe = (con.importe + elem.importe)
                                        WHERE concepto.idlaboral = elem.idlaboral 
                                        AND concepto.idconcepto = elem.tipoconcepto 
                                        AND concepto.nroliquidacion = elem.nroliq
                                        AND concepto.mes = elem.mes
                                        AND concepto.ano = elem.anio;
                                  ELSE
                                      INSERT INTO concepto (nroliquidacion,idlaboral,idconcepto,importe,imputacion,mes,ano)
                                      VALUES (elem.nroliq,elem.idlaboral,elem.tipoconcepto,elem.importe,'',elem.mes,elem.anio);
                                  END IF;
                   /*  Se modifica, pues el cambio de FinOS se debe hacer con sp de cambio de estado
 SELECT INTO rpersona * FROM persona WHERE nrodoc = elem.nrodoc AND tipodoc = elem.tipodoc;
                      SELECT INTO rcargo * FROM cargo WHERE cargo.idcargo = elem.nrocargo;
                       IF(rpersona.fechafinos <= rcargo.fechafinlab + INTEGER '90') THEN
                    
UPDATE persona SET fechafinos = rcargo.fechafinlab + INTEGER '90'
                                               WHERE nrodoc = rpersona.nrodoc and tipodoc = rpersona.tipodoc;
                       END IF;*/

 SELECT INTO r cambiarestadoconfechafinos(concat('persona.nrodoc =''', elem.nrodoc,''''));
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
