CREATE OR REPLACE FUNCTION ca.guardarliquidacioncabecera(integer, integer)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elidpersona INTEGER;
       elidliquidacion INTEGER;
       rliquidacion record;
BEGIN
/*  PRE: el idliquidacion es un id valido idem elidpersona*/

	elidliquidacion =$1;
    elidpersona = $2;

		SELECT INTO rliquidacion * FROM ca.liquidacion WHERE idliquidacion = elidliquidacion;
        DELETE FROM ca.liquidacioncabecera WHERE   
        		idliquidacion = elidliquidacion and
			    idpersona = elidpersona ;
     /*Dani modifico el 04/06/12 reemplazo   elidliquidacion =3 or elidliquidacion=4
 por  rliquidacion.idliquidaciontipo =3 or rliquidacion.idliquidaciontipo =4*/
      
  IF(rliquidacion.idliquidaciontipo =3 or rliquidacion.idliquidaciontipo =4) THEN -- si se trata de una liquidacion de aguinaldo
            INSERT INTO ca.liquidacioncabecera(idliquidacion, lcnombreyapellido, emlegajo, penrocuil, lctarea,
                           lccategoria,idcategoria, lcfechaingreso, lcantiguedad, lcbasico, lccontratacion, lcdireccion, lcobrasocial, idpersona )
            (  SELECT ca.liquidacion.idliquidacion, concat(  ca.persona.penombre , ' ' , ca.persona.peapellido) as apeynom,
		        ca.empleado.emlegajo, ca.persona.penrocuil, ca.empleado.emtarea,cadescripcion,categoria.idcategoria,ca.empleado.emfechadesde,
        		ca.antiguedadlaboral(ca.persona.idpersona, 
 ((date_trunc('month', concat(lianio,'-',limes,'-1')::date) + interval '1 month') - interval
'1 day')::date

,ca.liquidacion.idliquidacion) as lcantiguedad,
      			/*(cemonto*ceporcentaje) as*/ camonto
        		,  CT.contratodesc, concat(  ca.domicilio.docalle , ' ' , ca.domicilio.donro) as domicilio, ca.obrasocial.osdescripcion, ca.persona.idpersona
			  FROM ca.persona  
			  --NATURAL JOIN ca.domicilio 
LEFT  JOIN ca.domicilio 
on(ca.domicilio.iddomicilio=ca.persona.iddomicilio )
			  NATURAL JOIN ca.empleado 
			  NATURAL JOIN (SELECT idcontratotipo,ctdescripcion as contratodesc FROM ca.contratotipo ) as CT 
			  NATURAL JOIN ca.categoriaempleado
			  NATURAL JOIN ca.categoria 
			  NATURAL JOIN ca.categoriatipo
			  NATURAL JOIN ca.liquidacionempleado 
			  NATURAL JOIN ca.liquidacion 
			  NATURAL JOIN ca.liquidaciontipo 
			  LEFT JOIN ca.empleadoobrasocial  USING(idpersona)
                          LEFT JOIN ca.obrasocial USING(idobrasocial)
			 
                          JOIN ca.categoriatipoliquidacion using (idcategoria,idliquidaciontipo)
			  NATURAL JOIN ca.conceptoempleado
			  LEFT join ca.liquidacioncabecera as lc ON ( lc.idliquidacion = ca.liquidacionempleado.idliquidacion and  lc.idpersona = ca.liquidacionempleado.idpersona)
			   WHERE    ca.liquidacionempleado.idliquidacion = elidliquidacion and
			     ca.liquidacionempleado.idpersona = elidpersona     and
                  (nullvalue( lc.idliquidacion) and nullvalue(lc.idpersona) ) 

			     	     and ( cefechainicio <=  ((date_trunc('month', concat(lianio,'-',limes,'-1')::date) + interval '1 month') - interval
'1 day')::date 
                             and 
( date_trunc('month', concat(lianio,'-',limes,'-1')::date) <= cefechafin or nullvalue(cefechafin)) ) 

--MaLaPi 03-01-2022 Para el Aguinaldo tambien agrego el Tipo de Categoria (5) Licencia sin gece de haberes, pues se puede necesitar liquidar un proporcional
                             and	(idcategoriatipo = 1 or idcategoriatipo = 4 or idcategoriatipo = 5  )
			     and (idconcepto=32 or idconcepto=1092 or idconcepto=1232 or idconcepto=1245)
         
			);
        
        
        ELSE -- si es una liquidacion mensual
        INSERT INTO ca.liquidacioncabecera(idliquidacion, lcnombreyapellido, emlegajo, penrocuil, lctarea,
                           lccategoria,idcategoria, lcfechaingreso, lcantiguedad, lcbasico, lccontratacion, lcdireccion, lcobrasocial, idpersona )
            (  SELECT ca.liquidacion.idliquidacion, concat(  ca.persona.penombre , ' ' , ca.persona.peapellido) as apeynom,
		        ca.empleado.emlegajo, ca.persona.penrocuil, ca.empleado.emtarea,cadescripcion,categoria.idcategoria,ca.empleado.emfechadesde,
        		ca.antiguedadlaboral(ca.persona.idpersona, 
 ((date_trunc('month', concat(lianio,'-',limes,'-1')::date) + interval '1 month') - interval
'1 day')::date ,ca.liquidacion.idliquidacion) as lcantiguedad , camonto
        		,  CT.contratodesc, concat(  ca.domicilio.docalle , ' ' , ca.domicilio.donro) as domicilio, ca.obrasocial.osdescripcion, ca.persona.idpersona
			  FROM ca.persona  
			 left JOIN ca.domicilio  using(iddomicilio)
			  NATURAL JOIN ca.empleado 
			  NATURAL JOIN (SELECT idcontratotipo,ctdescripcion as contratodesc FROM ca.contratotipo ) as CT /*
			  NATURAL JOIN ca.categoriaempleado
			  NATURAL JOIN ca.categoria 
			  NATURAL JOIN ca.categoriatipo
			  NATURAL JOIN ca.liquidacionempleado 
			  NATURAL JOIN ca.liquidacion 
			  NATURAL JOIN ca.liquidaciontipo 
			  JOIN ca.categoriatipoliquidacion using (idcategoria,idliquidaciontipo)
			  LEFT JOIN ca.empleadoobrasocial  USING(idpersona)
                          LEFT JOIN ca.obrasocial USING(idobrasocial)
			  --NATURAL JOIN ca.conceptoempleado
			  LEFT join ca.liquidacioncabecera as lc ON ( lc.idliquidacion = ca.liquidacionempleado.idliquidacion 
                                                                      and  lc.idpersona = ca.liquidacionempleado.idpersona)
			  WHERE  
			     ca.liquidacionempleado.idliquidacion = elidliquidacion 
			     and ca.liquidacionempleado.idpersona = elidpersona     
                             and ( nullvalue(lc.idliquidacion) and nullvalue(lc.idpersona) ) 
			     and ( cefechainicio <=  ((date_trunc('month', concat(lianio,'-',limes,'-1')::date) + interval '1 month') - interval
'1 day')::date 
                         and 
( date_trunc('month', concat(lianio,'-',limes,'-1')::date) <= cefechafin or nullvalue(cefechafin)) ) 
                             and idcategoriatipo = 1  
			           
			);*/
 -- NATURAL JOIN ca.categoriaempleado
			--  NATURAL JOIN ca.categoria 
			--  NATURAL JOIN ca.categoriatipo
			  NATURAL JOIN ca.liquidacionempleado 
			  NATURAL JOIN ca.liquidacion 
			  NATURAL JOIN ca.liquidaciontipo 
			 -- JOIN ca.categoriatipoliquidacion using (idcategoria,idliquidaciontipo)
JOIN (select   idpersona,max(cefechainicio) as cefechainicio ,ca.liquidacion.idliquidacion,ca.categoriaempleado.idcategoriatipo
       from ca.categoriaempleado
      natural join  ca.conceptoempleado
         natural join  ca.liquidacion
        where  ( idcategoriatipo=1 ) and (ca.liquidacion.idliquidacion=elidliquidacion )
                and (ca.categoriaempleado.idpersona=elidpersona or elidpersona =0 )
    and
(
( cefechainicio  <= to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date+ interval '1 month' - interval '1 day')
and
(  cefechafin   >= to_timestamp(concat(lianio,'-',limes,'-1') ,'YYYY-MM-DD')::date or  nullvalue(cefechafin)
)
)

group by  idpersona,ca.liquidacion.idliquidacion,ca.categoriaempleado.idcategoriatipo

) as cat on (cat.idpersona=ca.persona.idpersona and cat.idliquidacion=ca.liquidacion.idliquidacion  )


			
JOIN ca.categoriaempleado on(  cat.idpersona=ca.categoriaempleado.idpersona and cat.cefechainicio=ca.categoriaempleado.cefechainicio  and cat.idcategoriatipo=ca.categoriaempleado.idcategoriatipo)
JOIN ca.categoria on(ca.categoriaempleado.idcategoria=ca.categoria.idcategoria )			
join  ca.categoriatipoliquidacion on (ca.categoriatipoliquidacion.idcategoria=ca.categoria.idcategoria and ca.categoriatipoliquidacion.idliquidaciontipo=ca.liquidacion.idliquidaciontipo)

	
			  LEFT JOIN ca.empleadoobrasocial  on(ca.empleadoobrasocial.idpersona=ca.persona.idpersona)
                          LEFT JOIN ca.obrasocial USING(idobrasocial)
			  LEFT join ca.liquidacioncabecera as lc ON ( lc.idliquidacion = ca.liquidacionempleado.idliquidacion 
                                                                      and  lc.idpersona = ca.liquidacionempleado.idpersona)
			  WHERE  
			     ca.liquidacionempleado.idliquidacion = elidliquidacion 
			     and ca.liquidacionempleado.idpersona = elidpersona     
                             and ( nullvalue(lc.idliquidacion) and nullvalue(lc.idpersona) ) 
			     and ( cat.cefechainicio <=  ((date_trunc('month', concat(lianio,'-',limes,'-1')::date) + interval '1 month') - interval
'1 day')::date 
                         and 
( date_trunc('month', concat(lianio,'-',limes,'-1')::date) <= cefechafin or nullvalue(cefechafin)) ) 
                             and cat.idcategoriatipo = 1  
			           
			);

        
        END IF;

return 1;
END;
$function$
