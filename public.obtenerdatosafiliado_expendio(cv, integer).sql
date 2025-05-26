CREATE OR REPLACE FUNCTION public.obtenerdatosafiliado_expendio(character varying, integer)
 RETURNS SETOF type_datosafiliado_expendio
 LANGUAGE plpgsql
AS $function$
DECLARE

--VARIABLES
   pnrodoc alias for $1;
   plabarra alias for $2; 
-- REGISTROS
   rdatostitu RECORD;
   rdatosper RECORD;
   losdatostarjeta RECORD;

--TIPOS
   rdatospersona type_datosafiliado_expendio;

BEGIN

  IF ((plabarra >=  30 AND  plabarra < 100 ) OR
              (plabarra > 129 AND plabarra < 200) )
                   THEN 

   PERFORM procesaralertaafiliado($1,1);
   FOR rdatospersona IN
   
    
    SELECT   nrodoc,  apellido, nombres,    fechanac ,fechainios ,    fechafinos ,      ctacteexpendio,tipodoc,
    barra ,    fechavtoreci::date ,    idosreci ,
    desosreci ,idestado ,desestado ,idreci ,desreci, CASE WHEN barra = 149 THEN true ELSE false END,null as nromutu,null as  nrodoctitu , 
    null as  tipodoctitu ,    null as idvin ,    null as barratitu , null as   mutual , null as  barramutu ,
    null as nromututitu ,null as nombreapetitu,telefono,email,edad,sexo as genero
   
    FROM (
    SELECT p.*,EXTRACT(year FROM age(p.fechanac)) as edad,null as fechavtoreci,null as idosreci, null as desosreci,estados.descrip as desestado,null as idreci, null as desreci, ctacteexpendio,
                  afilsosunc.idestado, CASE WHEN not nullvalue(aa.mutu) THEN aa.mutu
                WHEN not nullvalue(ad.mutu) THEN ad.mutu
                WHEN not nullvalue(anod.mutu) THEN anod.mutu
                WHEN not nullvalue(aso.mutu) THEN aso.mutu
                WHEN not nullvalue(arp.mutu) THEN arp.mutu
              END as tienemutu
             FROM persona AS p NATURAL JOIN  afilsosunc NATURAL JOIN estados 
			LEFT JOIN afiliauto as aa USING(nrodoc, tipodoc) 
			LEFT JOIN afilidoc as ad USING(nrodoc, tipodoc)
			LEFT JOIN afilinodoc as anod USING(nrodoc, tipodoc)
			LEFT JOIN afilisos as aso USING(nrodoc, tipodoc)
			LEFT JOIN afilirecurprop as arp USING(nrodoc, tipodoc)
	    WHERE nrodoc=pnrodoc AND p.barra=plabarra
	   UNION 
	   SELECT persona.*,EXTRACT(year FROM age(persona.fechanac)) as edad,fechavtoreci,idosreci,osreci.descrip as desosreci,estados.descrip as desestado,idreci,r.descrip as desreci,  true as ctacteexpendio,  afilreci.idestado,false as tienemutu 
             FROM persona NATURAL JOIN  afilreci NATURAL JOIN estados JOIN osreci USING(idosreci) 
             JOIN reciprocidades AS r USING(idreci)
	   WHERE nrodoc=pnrodoc AND persona.barra=plabarra) AS eltitu
       LOOP

       return next rdatospersona;
       end loop;

	
  ELSE    /*es un beneficiario*/
 
   FOR rdatospersona IN
 
     SELECT   nrodoc,    apellido,    nombres,    fechanac ,fechainios ,    fechafinos ,ctacteexpendio ,tipodoc    ,
    barra ,fechavtoreci,null as  idosreci ,
    null as osreci ,idestado,desestado ,    idreci,
    desreci, CASE WHEN barratitu = 149 THEN true ELSE false END, 
     null as nromutu , nrodoctitu ,    tipodoctitu ,
     idvin ,    barratitu ,    mutual ,    barramutu ,    nromututitu, nombreapetitu,telefono,email,edad,sexo as genero
   
    FROM (
    SELECT p.*,EXTRACT(year FROM age(p.fechanac)) as edad,null as fechavtoreci, benefsosunc.idestado,estados.descrip as desestado,null as idreci, null as desreci
           ,benefsosunc.nrodoctitu ,benefsosunc.tipodoctitu,benefsosunc.idvin ,benefsosunc.barratitu,benefsosunc.mutual,benefsosunc.barramutu,
           benefsosunc.nromututitu, ctacteexpendio,concat(pt.apellido ,', ',pt.nombres) as nombreapetitu
              

                FROM persona as p NATURAL JOIN benefsosunc NATURAL JOIN estados 
                JOIN afilsosunc ON benefsosunc.nrodoctitu=afilsosunc.nrodoc AND benefsosunc.tipodoctitu=afilsosunc.tipodoc
                JOIN persona as pt ON benefsosunc.nrodoctitu=pt.nrodoc AND benefsosunc.tipodoctitu=pt.tipodoc
		LEFT JOIN beneficiariosborrados as bb
               ON(bb.nrodoc=benefsosunc.nrodoc AND bb.tipodoc=benefsosunc.tipodoc AND bb.nrodoctitu=benefsosunc.nrodoctitu
                 AND  bb.tipodoctitu=benefsosunc.tipodoctitu)
		WHERE  NULLVALUE(bb.nrodoc) AND p.nrodoc=pnrodoc AND p.barra=plabarra

	    UNION 
           SELECT p.* ,EXTRACT(year FROM age(p.fechanac)) as edad,fechavtoreci, benefreci.idestado,estados.descrip as desestado,idreci,r.descrip as desreci
                ,nrodoctitu ,    tipodoctitu ,idvin,barratitu,null as mutual, null as barramutu,null as nromututitu
                 ,null as ctacteexpendio,concat(pt.apellido ,', ',pt.nombres) as nombreapetitu
                
            FROM persona  as p NATURAL JOIN benefreci  NATURAL JOIN estados 
              JOIN persona as pt ON benefreci.nrodoctitu=pt.nrodoc AND benefreci.tipodoctitu=pt.tipodoc
		
             JOIN reciprocidades AS r USING(idreci)
	    WHERE benefreci.nrodoc=pnrodoc  AND p.barra=plabarra
	 ) AS elbene
       LOOP

       return next rdatospersona;
       end loop;
    END IF;

 

END;
$function$
