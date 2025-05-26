CREATE OR REPLACE FUNCTION ca.f_valorconceptofijo(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       recconcepto record;
       rdiastrabajados record;
       datosvac record;
       rdiasjornadasemanal record;
       valordiabasico DOUBLE PRECISION;
       diasmensuales integer;
       diasnotrabajados  integer;
       diaslab  integer;
       diastrab  integer;
       montotope DOUBLE PRECISION;

BEGIN
--reemplazarparametros
--(integer, integer, integer, integer, varchar)
 /*    codliquidacion = $1;
     eltipo = $2;
     idpersona =  $3;
     elidconcepto = $4;
     laformula = $5; */

     --montotope=6941.14;

     --Antes la formula era asi
     -- Busco el monto del concepto
     SELECT INTO recconcepto *
     FROM ca.concepto
     WHERE idconcepto = $4 ;
   
     elmonto=recconcepto.comonto;


SELECT INTO rdiastrabajados * --busco los dias trabajados
            FROM ca.conceptoempleado
            WHERE idpersona =$3
                     AND idliquidacion = $1
                     AND idconcepto = 998 ;



 SELECT INTO rdiasjornadasemanal *
            FROM ca.conceptoempleado
            WHERE idpersona =$3
                     AND idliquidacion = $1
                     AND idconcepto = 1136 ;



--Luego del 18-11-2016  Dani modifico y la formula quedo asi :


  --devuelve los dias laborables mensuales
     SELECT into diaslab ceporcentaje
     FROM ca.conceptoempleado
     WHERE idpersona =$3 and idliquidacion= $1 and	idconcepto=1045 ;


  SELECT into diastrab ceporcentaje
     FROM ca.conceptoempleado
     WHERE idpersona =$3 and idliquidacion= $1 and idconcepto=1028;

          
  --Busco si la persona tiene liquidado tambien el concepto 1046 de vacaciones

      SELECT into datosvac FROM ca.conceptoempleado
      WHERE idpersona =$3 and idliquidacion= $1 and	idconcepto=1046 ;



      if found and ($4=1157 or $4=1158  or $4=1282  /*or $4=1283  or $4=1284*/) then
--si la persona tiene liquidado concepto 1046 de vacaciones entonces, debe cobrar el total del concepto 
        elmonto=elmonto;
     /* else --comento Dani 27062023 pero se tienenen cuenta mas abajo
          elmonto=(elmonto/diaslab)*diastrab;*/
      end if;
--Agrego Dani por pedido de JE pra que calcule el proporcional a la jornada laboral
   
--Dani comenta 27062023 porq referencia a un registro que no existe,se desconoce que se queria obtener aca pues en realdiad no funciona
/* if  (rdiasjornadasemanal.ceporcentaje<44) then
        elmonto =  (elmonto * rdiaslaborables.ceporcentaje) * 0.6666;

    end if; 
*/     

--Dani agrega 27062023 para que calcule el proporcional en caso de jornada reducida
if  (rdiasjornadasemanal.cemonto<44) then
   elmonto=(elmonto/rdiasjornadasemanal.ceporcentaje)*rdiasjornadasemanal.cemonto;

 end if;

---Dani agrego 26072023  por pedido de JE debe calcular el proporcional de todos los conceptos de tipo suplemento
if  (rdiastrabajados.ceporcentaje<30) then -- trabajo menos de 30 dias
    elmonto=(elmonto/30)*rdiastrabajados.ceporcentaje;

end if;

      UPDATE ca.conceptoempleado SET cemonto=round(elmonto::numeric,3 )  WHERE idconcepto = $4 and idpersona = $3  and idliquidacion=$1;
 return elmonto;
  --elmonto*0.5;
END;
$function$
