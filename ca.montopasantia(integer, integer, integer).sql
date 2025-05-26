CREATE OR REPLACE FUNCTION ca.montopasantia(integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/*
* Inicializa el asiento correspondiente a aquellos en los cuales solo se debe sumar lo dscontado en calidad de un concepto en particular
* PRE: el asiento debe estar creado

*/
DECLARE
      laformula varchar;
      laformulaaux varchar;
      elmes integer;
      elanio integer;
      elconcepto integer;
      datoconcepto record;
     
BEGIN
   
     SET search_path = ca, pg_catalog;
     elmes = $1;  
     elanio=$2;
elconcepto=$3;
/*lapersona=$4;*/
/*$3=pasantia*/
 /* reemplazarparametrosasiento
     '#', mes
     '&',anio
     '@', idcentrocosto
     '$', nroctacble

  */





  select into datoconcepto * from ca.categoriatipoliquidacion 
  where idcategoria=21 and idliquidaciontipo=1;
  
 /*select into diastrabajados from ca.conceptoempleado 
 natural join ca.liquidacion
  where limes=elmes and elanio=linaio and idpersona=lapersona and idconcepto=elconcepto ;
  

*/



return datoconcepto.camonto/30;



END;
$function$
