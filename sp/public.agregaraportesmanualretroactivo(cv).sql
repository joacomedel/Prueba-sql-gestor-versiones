CREATE OR REPLACE FUNCTION public.agregaraportesmanualretroactivo(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
--cursores
 data CURSOR FOR
            select *
            from ttaporte;
 cursorauxi refcursor;


--variables
 indice integer;
 indiceconcepto integer;
 tipod int2;
 imp numeric;
 impaporte numeric;
 tipoli varchar;
 nroliq varchar;
 cargoafi bigint;
 resp boolean;
 resp1 boolean;
 resp2 boolean;
 mesap integer;
 anioap integer;
 mesretro integer;
 nroconcepto varchar;
 nrod varchar;
--registros
dato RECORD;
raporte RECORD;
rconceptoret RECORD;
cuentac RECORD;
regconcepto RECORD;
elemcursor RECORD;
rnroliq RECORD;

BEGIN
/*
CREATE TEMP TABLE ttaporte(	nrodoc varchar(8),	barra int4,	nroliquidacion varchar(20),	idtipoliquidacion varchar(10),	idcargo int8,	mes int4,	mesesretroactivos int4,	anio int4,	importeconcepto numeric(7,2)) WITHOUT OIDS;
INSERT INTO ttaporte	 VALUES ('22619138',	 30, '409',	 'SUE',	 59824,	 1,	 4,	 2012,	 10727.7);
*/
resp = false;
open data;
FETCH data INTO dato;
   --ELIMINAR DE INFAPORTEFALTANTES al afiliado y sus beneficiarios
  /* SELECT  INTO resp1 *
   FROM eliminaraportefaltante(dato.nrodoc,dato.barra,dato.mes,dato.anio);
*/
--CARGAR APORTE y CONCEPTOS

tipoli=dato.nroliquidacion;
cargoafi = dato.idcargo;
mesap = dato.mes;
anioap = dato.anio;
nrod = dato.nrodoc;
mesretro = dato.mesesretroactivos;
WHILE found LOOP
--divido el importe del aporte en todos los meses correspondientes, insertando en la tabla aportes
--y tambien divido el importe del concepto 311 en los meses retroactivos
  SELECT INTO impaporte round(dato.importeconcepto/(dato.mesesretroactivos):: numeric,2);
  SELECT INTO cuentac * FROM cuentascontables WHERE cuentascontables.tipoafil = 'UNC';
  FOR indice IN 0..(dato.mesesretroactivos-1) LOOP

      SELECT INTO raporte * FROM aporte WHERE idcargo = dato.idcargo
                                        AND nroliquidacion = dato.nroliquidacion
                                       -- AND ano = dato.anio
                                        AND ano = (CASE WHEN (indice=0 and dato.mes=1) then dato.anio-1
                                                  ELSE dato.anio END)    
                                       -- AND mes = (dato.mes-indice);
                                        AND mes = (SELECT date_part('month',to_date(concat ( dato.anio::varchar ,'-', dato.mes::varchar,'-','10'), 'YYYY MM DD')-(30*indice))::integer);

      IF NOT FOUND THEN
      
               INSERT INTO aporte (ano,automatica,fechaingreso,idcargo,idcertpers,idlaboral,idlic,idrecibo,idresolbe,idtipoliquidacion,importe,mes,nroliquidacion,nrocuentac)
               VALUES ((CASE WHEN (indice=0 and dato.mes=1) then dato.anio-1
                                                  ELSE dato.anio END) ,true,current_date,dato.idcargo,null,dato.idcargo,null,null,null,dato.idtipoliquidacion,impaporte,
((SELECT date_part('month',to_date(concat ( dato.anio::varchar,'-',dato.mes::varchar,'-','10'), 'YYYY MM DD')-(30*indice))::integer))
,dato.nroliquidacion,cuentac.nrocuentac);

      ELSE
               UPDATE aporte SET importe = impaporte
                      WHERE idcargo = dato.idcargo
                       AND nroliquidacion =  dato.nroliquidacion
                       AND ano = dato.anio
                       AND mes = dato.mes;
               
      END IF;

END LOOP;--del for

FETCH data INTO dato;
END LOOP;
CLOSE data;


OPEN cursorauxi FOR SELECT * FROM concepto
                         WHERE concepto.nroliquidacion= tipoli
                         AND concepto.idlaboral=cargoafi AND concepto.idconcepto <> (-51);

FETCH cursorauxi INTO elemcursor;


  WHILE found LOOP
    --  nroconcepto =elemcursor.idconcepto;;
     SELECT INTO imp round(elemcursor.importe/(mesretro):: numeric,2);
      FOR indiceconcepto IN 0..(mesretro-1) LOOP


      SELECT INTO rnroliq *
      FROM public.liquidacion
      WHERE public.liquidacion.anio = (CASE WHEN (indiceconcepto=0 and mesap=1) then (anioap-1)  ELSE anioap END)::integer
      AND  public.liquidacion.mes = ((SELECT date_part('month',to_date(concat ( anioap::varchar,'-',mesap::varchar,'-','10'), 'YYYY MM DD')-(30*indiceconcepto))::integer))
      LIMIT 1;
      
      SELECT INTO rconceptoret * FROM concepto WHERE concepto.nroliquidacion= rnroliq.nroliquidacion
                                        AND concepto.idlaboral=cargoafi 
                                        AND concepto.idconcepto = elemcursor.idconcepto;

       IF NOT FOUND THEN

               INSERT INTO concepto(nroliquidacion,idlaboral,idconcepto,importe,ano,mes)
                  VALUES(rnroliq.nroliquidacion,cargoafi,elemcursor.idconcepto,imp,rnroliq.anio, rnroliq.mes);

       ELSE
               UPDATE concepto SET importe = imp
                      WHERE concepto.nroliquidacion= rnroliq.nroliquidacion
                      AND concepto.idlaboral=cargoafi 
                      AND concepto.idconcepto = elemcursor.idconcepto;
       END IF;
     --  nroconcepto= elemcursor.idconcepto;

       END LOOP;--del for x cada concepto
FETCH cursorauxi INTO elemcursor;
END LOOP; --del cursor de conceptos, mientras hayan conceptos para ese aporte
CLOSE cursorauxi;



  



--ACTUALIZAR FECHA FIN OBRA SOCIAL PARA TODOS EL AFILIADO
/*
select * into resp2
       from actualizarfechafinobrasocial(nrod,bar);
*/
--ACTUALIZAR FECHA FIN OBRA SOCIAL PARA TODOS EL AFILIADO Y SUS beneficiarios
select * into resp2
      FROM cambiarestadoconfechafinos(concat ( 'persona.nrodoc =''', nrod ,'''') );


-- Falta actualizar el Contador de Carencia para la persona


--
resp = resp or resp1 or resp2;
return resp;
end;
$function$
