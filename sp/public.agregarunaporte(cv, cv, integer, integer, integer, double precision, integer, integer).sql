CREATE OR REPLACE FUNCTION public.agregarunaporte(character varying, character varying, integer, integer, integer, double precision, integer, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
	--PARAMETROS
    usuario alias for $1;
	nroDocu alias for $2;
    barraEmp alias for $3;
	mesAp alias for $4;
	anioAp alias for $5;
	imp alias for $6;
	idformapago alias for $8;


	
	--RECORDS
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	aux2 RECORD;
	td record;
	cuentac RECORD;
	elconcepto  RECORD;
	--CURSORES
	beneficiarios CURSOR FOR
	              SELECT
                        benefsosunc.nrodoc,
                        persona.barra
                  FROM benefsosunc
                  INNER JOIN afilsosunc ON (benefsosunc.nrodoctitu=afilsosunc.nrodoc)
                       AND (benefsosunc.tipodoctitu=afilsosunc.tipodoc)
                  INNER JOIN persona ON (benefsosunc.nrodoc=persona.nrodoc)
                       AND (benefsosunc.tipodoc=persona.tipodoc)
                  WHERE  (afilsosunc.barra = barraEmp) AND  (afilsosunc.nrodoc = nroDocu);
	
	--VARIABLES
	nrodocanterior varchar;
	tipodocanterior integer;
	numcargo integer;
	idcert integer;

	lic integer;
	reci bigint;
	resol integer;
	fechaini date;
	fechafin date;
	resultado boolean;
	resultado2 boolean;
	tdoc integer;
	/*barraEmp smallint;*/
	tipinf varchar;
	nroinforme bigint;
	tipoLiquidacion varchar;
	nroLiq varchar;
	idConc varchar;
	imput varchar;
	jubpen boolean;
    idaportev bigint;
    centrov integer;
	/*nroDocu varchar;*/
	

vidusuario integer;

BEGIN
reci = $7;
--barraEmp = $3;
--nroDocu = $2;
idConc = '311';
resultado = true;

/*El nroTipoInforme lo tengo que recuperar a partir del nro de Liquidacion/
*/
SELECT nroliquidacion, idtipoliq into aux2
       FROM	 liquidacion
       WHERE (liquidacion.mes = mesAp)
             AND (liquidacion.anio = anioAp)
       limit 1;
IF found THEN
   tipoLiquidacion=aux2.idtipoliq;
   nroLiq=aux2.nroliquidacion;
ELSE
    --return false; -- quiere decir que AUN no existe una liquidacion para el mes que se quiere pagar
    tipoLiquidacion='SUE';
    nroLiq=anioAp * 100000 + mesAp * 100 + 10;
END IF;
/*
  Recuperamos el nroInforme a partir del Nro Liquidacion obtenido
*/
Select INTO td tipoinforme,nrotipoinforme
       from infaporrecibido
       where nroliquidacion = nroLiq
       LIMIT 1;

IF FOUND THEN
   nroinforme = td.nrotipoinforme;
ELSE
    nroinforme = anioAp * 100 + mesAp;
END IF;

/*
Si el afiliado es Jubilado o Pensionado
---------------------------------------
*/
if barraEmp>=35 THEN
   tipinf = 'JubPen';
   IF barraEmp=35 THEN                    --JUBILADO
      SELECT * into aux2
             FROM afiljub
             NATURAL JOIN persona
             INNER JOIN afilsosunc
                            ON (afiljub.nrodoc=afilsosunc.nrodoc)
                            AND (afiljub.tipodoc=public.afilsosunc.tipodoc)
             where afilsosunc.nrodoc = nroDocu
                   and afilsosunc.barra = barraEmp;
      IF FOUND THEN
         idcert = aux2.idcertpers;
         tdoc=aux2.tipodoc;
         fechaini = aux2.fechainios;
      END IF;
   END IF;
   IF barraEmp=36 THEN                    --PENSIONADO
       SELECT * into aux2 FROM afilpen
               NATURAL JOIN persona
               INNER JOIN afilsosunc ON (afilpen.nrodoc=afilsosunc.nrodoc AND afilpen.tipodoc=public.afilsosunc.tipodoc)
        WHERE afilsosunc.nrodoc = nroDocu AND afilsosunc.barra = barraEmp;
       IF FOUND THEN
          idcert = aux2.idcert;
          tdoc = aux2.tipodoc;
          fechaini = aux2.fechainios;
       END IF;
   END IF;

   fechafin = to_date(concat ( '10-' , mesAp , '-' , anioAp), 'dd-MM-yyyy')+ '1 month'::interval;

   jubpen = true;
   numcargo = idcert;
   SELECT INTO cuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'JUB';
/*----------------------------------------------------------------------------*/
ELSE   -- BARRA < 35    
   jubpen = false;
   IF barraEmp=34 THEN                    --BECARIO
   tipinf = 'Becario';
        SELECT INTO cuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'UNC';
        SELECT * into aux FROM afilibec
               NATURAL JOIN persona
               INNER JOIN afilsosunc ON (afilibec.nrodoc=afilsosunc.nrodoc AND afilibec.tipodoc=public.afilsosunc.tipodoc)
               WHERE afilsosunc.nrodoc = nroDocu AND afilsosunc.barra = barraEmp;
       IF FOUND THEN
          idcert = aux.idresolbe;
          tdoc = aux.tipodoc;
          fechaini = aux.fechainios;
          numcargo = idcert;

   fechafin = to_date(concat ( '10-' , mesAp , '-' , anioAp), 'dd-MM-yyyy')+ '1 month'::interval;

       END IF;
     
   ELSE  -- Afiliado en uso de Licencia
        SELECT INTO cuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'LIC';
        tipinf = 'Licencia';
        SELECT INTO aux     -- Busca el cargo del afiliado controla que este vigente
          public.cargo.idcargo,
          public.cargo.fechainilab,
          public.cargo.fechafinlab,
          public.cargo.tipodoc,
          public.cargo.nrodoc,
          public.cargo.legajosiu
   FROM public.cargo
        INNER JOIN public.afilsosunc ON (public.cargo.nrodoc=public.afilsosunc.nrodoc)
        AND (public.cargo.tipodoc=public.afilsosunc.tipodoc)
   WHERE  (public.afilsosunc.nrodoc = nroDocu)
          AND (public.afilsosunc.barra = barraEmp)
          AND (cargo.fechainilab< CURRENT_DATE)
          AND (cargo.fechafinlab>= CURRENT_DATE);

   IF NOT FOUND THEN
      /*Reportarlo como que no existe el cargo o NO ESTA VIGENTE*/
      tipinf = 'NOEXISTELABORAL';
      SELECT INTO resultado2 *
      FROM agregareninforme(tipinf,cast(nroinforme as bigint),current_date,aux.idcargo,nroliq,nroDocu,cast(barraEmp as smallint));
      /*Lo busco para ver si se ingreso en el informe de aportes recibidos*/
   ELSE /*IF NOT FOUND FROM cargo*/
       numcargo = aux.idcargo;
       fechaini = aux.fechainilab;
      /*  --modifique para aumentar un mes fechafinos (Karina)*/
   fechafin = to_date(concat ( '10-' , mesAp , '-' , anioAp), 'dd-MM-yyyy')+ '1 month'::interval;

       --fechafin = aux.fechafinlab; (antes de 17/07/2008)
       tdoc = aux.tipodoc;

       /*SELECT idlic into aux2     --Busco el Registro de Licencia
          FROM licsinhab
          where licsinhab.idcargo = numcargo;*/
         --Dani reeemplazo 2024-09-11 para que encunetre una licencia no importa el cargo
               SELECT idlic into aux2     --Busco el Registro de Licencia
               FROM cargo natural join licsinhab
               where nrodoc=nroDocu;
       if found then
          lic= aux2.idlic;
       else
                   SELECT idlicencias into aux2     --Busco el Registro de Licencia
                   FROM licencias
                    where licencias.legajosiu = aux.legajosiu;
                  if found then
                      lic= aux2.idlicencias;
                     else
                     return false; -- quiere decir que AUN no ha iniciado los tramites de Licencia sin goce de Haberes
                  end if;
       end if;
    END IF;
    END IF;
END IF;

/*
  Agrego el informe del pago
*/
select INTO resultado2  *
       FROM agregareninforme(cast(tipinf as varchar),cast(nroinforme as bigint),current_date,numcargo,cast(nroLiq as varchar),cast(nroDocu as varchar),cast(barraEmp as smallint));
IF NOT resultado2 THEN
   return false;
END IF;

 /*
       Borra los Registros en Aporte faltante, del afiliado y sus beneficiarios
       */
       open beneficiarios;
       FETCH beneficiarios INTO elem;
       WHILE  found LOOP
           DELETE
           FROM infaportesfaltantes
           WHERE infaportesfaltantes.mes = mes
             AND infaportesfaltantes.anio = anio
             AND infaportesfaltantes.nrodoc = elem.nrodoc
             AND infaportesfaltantes.barra = elem.barra;
           FETCH beneficiarios INTO elem;
       END LOOP;
       CLOSE beneficiarios;

imput = concat ( 'PagoPorCaja ' , nroDocu ,  ' ' , mesAp , anioAp , ' ' , current_date);

--SELECT INTO resultado * FROM cambiarestado(true,fechaini,fechafin,numcargo,nroliq,nroDocu,tdoc);




       
/*
  Inserta el aporte
*/
INSERT INTO aporte (
            ano,
            automatica,
            fechaingreso,
            idcargo,
            idcertpers,
            idlaboral,
            idlic,
            idrecibo,
            idresolbe,
            idtipoliquidacion,
            importe,
            mes,
            nroliquidacion,
            nrocuentac,
            idformapagotipos)
       VALUES (anioAp,true,current_date,numcargo,idcert,numcargo,lic,reci,resol,tipoLiquidacion,imp,mesAp,nroLiq,cuentac.nrocuentac,idformapago);

--SELECT max(idaporte) INTO idaportev  FROM aporte;
SELECT currval('aporte_idaporte_seq') INTO idaportev;

-- select into valor idcentroregional from centroregionaluso;
SELECT  into centrov centro();

  IF jubpen THEN
       INSERT INTO aportejubpen (nrodoc,tipodoc,importe,fechainiaport,fechafinaport,mes,anio,cancelado,barra,ajpfechaingreso,idaporte)
               VALUES (aux2.nrodoc,aux2.tipodoc,$6,to_date(concat ( '10-' , mesAp  , '-' , anioAp), 'dd-MM-yyyy'),fechafin,mesAp,anioAp,true,barraEmp,CURRENT_DATE,idaportev);

       INSERT INTO aportessinfacturas(nrodoc,tipodoc,mes,anio,centro,idaporte)
              VALUES(aux2.nrodoc, aux2.tipodoc,mesAp,anioAp,centrov,idaportev);
  ELSE
       INSERT INTO aporteuniversidad (nrodoc,tipodoc,importe,fechainiaport,fechafinaport,mes,anio,cancelado,barra,alicfechaingreso,idaporte)
               VALUES (aux.nrodoc,aux.tipodoc,$6,to_date(concat ( '10-' , mesAp  , '-' , anioAp), 'dd-MM-yyyy'),fechafin,mesAp,anioAp,true,barraEmp,CURRENT_DATE,idaportev);

       INSERT INTO aportessinfacturas(nrodoc,tipodoc,mes,anio,centro,idaporte)
              VALUES(aux.nrodoc, aux.tipodoc,mesAp,anioAp,centrov,idaportev);
  END IF;

  /*  Inserta el Asiento en concepto */
  SELECT INTO elconcepto * FROM concepto WHERE mes = mesAp and ano = anioAp and nroliquidacion = nroliq and idlaboral = numcargo;
  IF NOT FOUND THEN
     INSERT INTO concepto ( nroliquidacion,  idlaboral, idconcepto, importe, imputacion, mes,ano)
     VALUES (nroliq,numcargo,idConc,imp,'',mesAp,anioAp);
  ELSE
      UPDATE concepto SET importe = importe+imp
      WHERE mes = mesAp and ano = anioAp and nroliquidacion = nroliq and idlaboral = numcargo;
  END IF;

IF iftableexistsparasp('temp_aportejubpen') THEN
 
INSERT INTO aporteestado(idaporte,aeobservacion,idestadotipo,aefechafin,idcentroregionaluso) VALUES(currval('aporte_idaporte_seq'::regclass),'Al ingresar aportes de JubPen',1,null,centro()); 
     

ELSE
--MaLaPi 05/05/2020 La facultad usa otro SP... agregaraportes();
--INSERT INTO aporteestado(idaporte,aeobservacion,idestadotipo,aefechafin,idcentroregionaluso) VALUES(currval('aporte_idaporte_seq'::regclass),'Al ingresar aportes de la Facultad',1,now(),centro());
--INSERT INTO aporteestado(idaporte,aeobservacion,idestadotipo,aefechafin,idcentroregionaluso) VALUES(currval('aporte_idaporte_seq'::regclass),'Al ingresar aportes de de la Facultad',7,null,centro()); 
 

 --- SELECT INTO resultado * FROM cambiarestadoconfechafinos(concat ( 'persona.nrodoc =''', nroDocu ,''' and persona.tipodoc = ', tdoc) );
END IF;





return resultado;
end;
$function$
