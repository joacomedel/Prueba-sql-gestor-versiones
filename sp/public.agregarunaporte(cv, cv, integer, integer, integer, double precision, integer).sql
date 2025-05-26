CREATE OR REPLACE FUNCTION public.agregarunaporte(character varying, character varying, integer, integer, integer, double precision, integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*agregarunaportes" ('Malapi','14101076',3,2006,153.23)
$1 Usuario
$2 NroDoc
$3 Barra
$4 Mes
$5 Año
$6 Importe
$7 Nro de Recibo

*/
DECLARE
	--PARAMETROS
    usuario alias for $1;
	nroDocu alias for $2;
    barraEmp alias for $3;
	mesAp alias for $4;
	anioAp alias for $5;
	imp alias for $6;


	
	--RECORDS
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	aux2 RECORD;
	td record;
	cuentac RECORD;
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

	/*nroDocu varchar;*/
	
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
             AND (liquidacion.anio = anioAp);
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
   fechafin = to_date(concat ( '10-' , mesAp + 1  , '-' , anioAp), 'dd-MM-yyyy');
   INSERT INTO aportejubpen (nrodoc,tipodoc,importe,fechainiaport,fechafinaport,mes,anio,cancelado,barra,ajpfechaingreso)
               VALUES (aux2.nrodoc,aux2.tipodoc,$6,to_date(concat ( '10-' , mesAp  , '-' , anioAp), 'dd-MM-yyyy'),fechafin,mesAp,anioAp,true,barraEmp,CURRENT_DATE);
   numcargo = idcert;
   SELECT INTO cuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'JUB';
/*----------------------------------------------------------------------------*/
ELSE   -- BARRA < 35    -- Afiliado en uso de Licencia
   SELECT INTO cuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'LIC';
   tipinf = 'Licencia';
   SELECT INTO aux     -- Busca el cargo del afiliado controla que este vigente
          public.cargo.idcargo,
          public.cargo.fechainilab,
          public.cargo.fechafinlab,
          public.cargo.tipodoc,
          public.cargo.nrodoc
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
      FROM agregareninforme(tipinf,cast(nroinforme as bigint),current_date,aux.idcargo,nroliq,nroDocu,barraEmp);
      /*Lo busco para ver si se ingreso en el informe de aportes recibidos*/
   ELSE /*IF NOT FOUND FROM cargo*/
       numcargo = aux.idcargo;
       fechaini = aux.fechainilab;
       fechafin = to_date(concat ( '10-' , mesAp + 1  , '-' , anioAp), 'dd-MM-yyyy'); --modifique para aumentar un mes fechafinos (Karina)
       --fechafin = aux.fechafinlab; (antes de 17/07/2008)
       tdoc = aux.tipodoc;
        INSERT INTO aportelicsinhab (nrodoc,tipodoc,importe,fechainiaport,fechafinaport,mes,anio,cancelado,barra,alicfechaingreso)
               VALUES (aux.nrodoc,aux.tipodoc,$6,to_date(concat ( '10-' , mesAp  , '-' , anioAp), 'dd-MM-yyyy'),fechafin,mesAp,anioAp,true,barraEmp,CURRENT_DATE);

       SELECT idlic into aux2     --Busco el Registro de Licencia
          FROM licsinhab
          where licsinhab.idcargo = numcargo;
       if found then
          lic= aux2.idlic;
       else
           return false; -- quiere decir que AUN no ha iniciado los tramites de Licencia sin goce de Haberes
       end if;

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
            nrocuentac)
       VALUES (anioAp,true,current_date,numcargo,idcert,numcargo,lic,reci,resol,tipoLiquidacion,imp,mesAp,nroLiq,cuentac.nrocuentac);



/*
   Interta el Asiento en concepto
*/
INSERT INTO concepto (
            nroliquidacion,
            idlaboral,
            idconcepto,
            importe,
            imputacion)
            VALUES (nroliq,numcargo,idConc,imp,'');
return resultado;
end;
$function$
