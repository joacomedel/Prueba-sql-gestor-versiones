CREATE OR REPLACE FUNCTION ca.calcularlicenciaconcepto(date, date)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/* New function body */
DECLARE


 cursorempleado refcursor;
 unempleado record;
 cant integer;
 lafechadesde date;
 lafechahasta date;
BEGIN
     lafechadesde = $1;
     lafechahasta =$2;

     INSERT INTO templicenciaconcepto ( idpersona , peapellido , penombre ,  lifechainicio , lifechafin , ltdescripcion , idconcepto , cantdias)  (
     SELECT idpersona,peapellido,penombre,lifechainicio,lifechafin,ltdescripcion,ca.mapeolicenciaconcepto.idconcepto as idconcepto,
     CASE WHEN ( lifechainicio <= lafechadesde  )
           and ( lafechadesde  <= lafechahasta )
           and ( lafechahasta <= lifechafin)
          THEN ca.cantidaddiassegunlicencia(lafechadesde , lafechahasta ,ca.licenciatipo .idlicenciatipo)
     WHEN  (    lafechadesde <= lifechainicio)
           and (lifechainicio <= lafechahasta )
           and (lafechahasta  <= lifechafin)
          THEN ca.cantidaddiassegunlicencia(lifechainicio,lafechahasta , ca.licenciatipo .idlicenciatipo)
     WHEN (lifechainicio <= lafechadesde )
           and (lafechadesde  <= lifechafin)
           and (lifechafin <= lafechahasta  )
          THEN ca.cantidaddiassegunlicencia(lafechadesde  ,lifechafin, ca.licenciatipo .idlicenciatipo)
     WHEN ( lafechadesde  <=lifechainicio )
           and (lifechainicio<= lifechafin )
           and (lifechafin <= lafechahasta )
         THEN ca.cantidaddiassegunlicencia(lifechainicio,lifechafin, ca.licenciatipo .idlicenciatipo) END as cantdias
     FROM ca.licencia 	
     NATURAL JOIN ca.persona 	
     NATURAL JOIN ca.empleado 	
     NATURAL JOIN ca.licenciatipo 	
     LEFT JOIN ca.mapeolicenciaconcepto on (ca.mapeolicenciaconcepto.idlicenciatipo=ca.licenciatipo.idlicenciatipo) 	
     LEFT JOIN ca.concepto on (ca.mapeolicenciaconcepto.idconcepto=ca.concepto.idconcepto)
     WHERE true  	AND ( (lafechadesde <= lifechainicio    AND lifechainicio <= lafechahasta )		
           	OR(lafechadesde  <= lifechafin AND lifechafin <= lafechahasta )	)
            AND ltmigrarsueldo
     ORDER BY peapellido,lifechainicio
    );


 UPDATE templicenciaconcepto
 SET idliquidaciontipo =t.idliquidaciontipo
          FROM (
               SELECT idpersona,ca.categoriatipoliquidacion.idliquidaciontipo
                FROM ca.categoriaempleado
               NATURAL JOIN ca.categoriatipoliquidacion
                JOIN  templicenciaconcepto using (idpersona)
               WHERE cefechainicio<= NOW() AND (nullvalue(cefechafin)or cefechafin>=(Now() - '1 month'::interval  ))

               
           ) as t
  WHERE templicenciaconcepto.idpersona=t.idpersona;


     
RETURN true;
END;
$function$
