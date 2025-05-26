CREATE OR REPLACE FUNCTION public.agregaraportesmanual(character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
nrodoc varchar(8)
barra int4
nroliquidacion varchar(20)
idcargo int8
mes int4
anio int4
idconcepto varchar(10)
importeconcepto numeric(6,2)
*/

DECLARE

data CURSOR FOR
            select *
            from ttaporte;

dato RECORD;
benefs record;
tipodoc int2;
imp numeric(6,2);
nroliq varchar;
idcar int8;
mesap int4;
anioap int4;
tipoli varchar;
resp boolean;
resp1 boolean;
resp2 boolean;
fecha date;
nrod varchar;
bar int2;

begin
resp = false;
open data;
fetch data into dato;
     nroliq=dato.nroliquidacion;
     idcar=dato.idcargo;
     mesap=dato.mes;
     anioap=dato.anio;
     nrod = dato.nrodoc;
     bar = dato.barra;

--ELIMINAR DE INFAPORTEFALTANTES al afiliado y sus beneficiarios
close data;
select * into resp1
       from eliminaraportefaltante(nrod,bar,mesap,anioap);

--CARGAR APORTE y CONCEPTOS
open data;
imp=0;
fetch data into dato;
while found loop
      insert into concepto
             VALUES(dato.nroliquidacion,dato.idcargo,dato.idconcepto,dato.importeconcepto);
      imp = imp + dato.importeconcepto;
      fetch data into dato;
end loop;
close data;

SELECT into tipoli
       public.liquidacion.idtipoliq
       FROM public.liquidacion
       WHERE  (public.liquidacion.nroliquidacion=nroliq);
INSERT INTO aporte(nroliquidacion,idlaboral,mes,ano,idtipoliquidacion,importe,fechaingreso,automatica)
       VALUES(nroliq,idcar,mesap,anioap,tipoli,imp,current_date,false);

--ACTUALIZAR FECHA FIN OBRA SOCIAL PARA TODOS EL AFILIADO

select * into resp2
       from actualizarfechafinobrasocial(nrod,bar);
       
-- Falta actualizar el Contador de Carencia para la persona


--
resp = resp or resp1 or resp2;
return resp;
end;
$function$
