CREATE OR REPLACE FUNCTION public."agregarunaporte1(varchar, varchar, integer, integer, integer, d"(character varying, character varying, integer, integer, integer, double precision)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*agregarunaportes" ('Malapi','14101076',3,2006,153.23)
$1 Usuario
$2 NroDoc
$3 Barra
$4 Mes
$5 Año
$6 Importe

*/
DECLARE
	--PARAMETROS
    usuario alias for $1;
	--nroDoc alias for $2;
    --barra alias for $3;
	mesAp alias for $4;
	anioAp alias for $5;
	imp alias for $6;

	
	--RECORDS
	elem RECORD;
	anterior RECORD;
	aux RECORD;
	aux2 RECORD;
	td record;
	
	--CURSORES
	beneficiarios CURSOR FOR
	              SELECT
                        public.benefsosunc.nrodoc,
                        public.persona.barra
                  FROM public.benefsosunc
                       INNER JOIN public.afilsosunc ON (public.benefsosunc.nrodoctitu=public.afilsosunc.nrodoc)
                       AND (public.benefsosunc.tipodoctitu=public.afilsosunc.tipodoc)
                       AND (public.benefsosunc.barratitu=public.afilsosunc.barra)
                       INNER JOIN public.persona ON (public.benefsosunc.nrodoc=public.persona.nrodoc)
                       AND (public.benefsosunc.tipodoc=public.persona.tipodoc)
                  WHERE  (public.afilsosunc.barra = barraEmp)
                         AND  (public.afilsosunc.nrodoc = nroDoc);
	
	--VARIABLES
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
	tdoc integer;
	barraEmp smallint;
	tipinf varchar;
	nroinforme bigint;
	tipoLiquidacion varchar;
	nroLiq varchar;
	idConc varchar;
	imput varchar;
	nroDoc varchar;
	
BEGIN
barraEmp = $3;
nroDoc = $2;
idConc = '311';
resultado = true;
/*
Si el afiliado es Jubilado o Pensionado
---------------------------------------
*/
if barraEmp>=35 THEN
   tipinf = 'JubPen';
   IF barraEmp=35 THEN                    --JUBILADO
      SELECT idcertpers,afiljub.tipodoc into aux2
                 FROM afiljub
                      INNER JOIN afilsosunc
                            ON (afiljub.nrodoc=afilsosunc.nrodoc)
                            AND (afiljub.tipodoc=public.afilsosunc.tipodoc)
                 where afilsosunc.nrodoc = nroDoc
                       and afilsosunc.barra = barraEmp;
      IF FOUND THEN
         idcert = aux2.idcertpers;
         tdoc=aux2.tipodoc;
      END IF;
   END IF;
   IF barraEmp=36 THEN                    --PENSIONADO
       SELECT idcert,afilpen.tipodoc into aux2
          FROM afilpen
               INNER JOIN afilsosunc
                            ON (afilpen.nrodoc=afilsosunc.nrodoc)
                            AND (afilpen.tipodoc=public.afilsosunc.tipodoc)
          where afilsosunc.nrodoc = nroDoc
                and afilsosunc.barra = barraEmp;
       IF FOUND THEN
          idcert = aux2.idcert;
          tdoc = aux2.tipodoc;
       END IF;
   END IF;
   UPDATE aportejubpen    --Registro que la deuda ha sido cancelada
              SET cancelado=true
              WHERE
                   aportejubpen.nrodoc =nroDoc
                   AND aportejubpen.barra = barraEmp
                   AND aportejubpen.mes = mesAp
                   AND aportejubpen.anio = anioAp;
   fechaini = CURRENT_DATE - INTEGER '90';
   fechafin = CURRENT_DATE + INTEGER '30';
   numcargo = idcert;
/*----------------------------------------------------------------------------*/
ELSE   -- BARRA < 35    -- Afiliado en uso de Licencia
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
   WHERE  (public.afilsosunc.nrodoc = nroDoc)
          AND (public.afilsosunc.barra = barraEmp)
          AND (cargo.fechainilab< CURRENT_DATE)
          AND (cargo.fechafinlab>= CURRENT_DATE);
          
   IF NOT FOUND THEN
      /*Reportarlo como que no existe el cargo o NO ESTA VIGENTE*/
      tipinf = 'NOEXISTELABORAL';
      SELECT INTO resultado2 *
      FROM agregareninforme(tipinf,cast(nroinforme as bigint),current_date,aux.idcargo,nroliq,nroDoc,barraEmp);
      /*Lo busco para ver si se ingreso en el informe de aportes recibidos*/
   ELSE /*IF NOT FOUND FROM cargo*/
       numcargo = aux.idcargo;
       fechaini = aux.fechainilab;
       fechafin = aux.fechafinlab;
       tdoc = aux.tipodoc;
       SELECT idlic into aux2     --Busco el Registro de Licencia
          FROM licsinhab
          where licsinhab.idcargo = numcargo;
       if found then
          lic= aux2.idlic;
       else
           return false; -- quiere decir que AUN no ha iniciado los tramites de Licencia sin goce de Haberes
       end if;
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
    END IF;
END IF;

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
    return false; -- quiere decir que AUN no existe una liquidacion para el mes que se quiere pagar
END IF;
/*
  Recuperamos el nroInforme a partir del Nro Liquidacion obtenido
*/
Select INTO td tipoinforme,nrotipoinforme
       from infaporrecibido
       where nroliquidacion = nroLiq;
nroinforme = td.nrotipoinforme;
/*
  Agrego el informe del pago
*/
select INTO resultado2  *
       FROM agregareninforme(cast(tipinf as varchar),cast(nroinforme as bigint),current_date,numcargo,cast(nroLiq as varchar),cast(nroDoc as varchar),barraEmp);
IF NOT resultado2 THEN
   return false;
END IF;

imput = concat('PagoPorCaja ' , nrodoc , barraEmp , ' ' , mesAp , anioAp , ' ' , current_date);

SELECT INTO resultado *
       FROM cambiarestado(true,fechaini,fechafin,numcargo,nroliq,nroDoc,tdoc);

/*
  Genera el nuevo recibo
*/
INSERT INTO recibo (
            importerecibo,
            imputacionrecibo
            )
            VALUES (imp,imput);
SELECT * INTO aux
       FROM recibo
       WHERE
            recibo.imputacionrecibo = imput;
reci = aux.idrecibo;
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
            nroliquidacion)
       VALUES (anioAp,true,current_date,numcargo,idcert,numcargo,lic,reci,resol,tipoLiquidacion,imp,mesAp,nroLiq);
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
