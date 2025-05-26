CREATE OR REPLACE FUNCTION public.agregarmontosdedescuentos()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*
Ingresa la informacion de montos para descuentos disponibles usando la informacion de la tabla dh21 con el concepto 357
*/
/*Dani agrego el 16082022 para que tambien ingrese la informacion de montos para descuentos disponibles usando la informacion de la tabla ca.conceptoempleado con el concepto 357
*/
DECLARE
	alta refcursor;
 	verifica RECORD;
        elem RECORD;
        resultado boolean;
        rexcentos record;
        rliquidacion record; 
       
	
	
BEGIN
/*MaLaPi Hay que ver como va a informar los montos de descuentos para el personal de sosunc. 
  Tener en cuenta que una persona de Sosunc, puede tambien trabajar en la unc.*/

-- MaLaPi Doy de baja todos los activos que no sean de este mes. 
UPDATE ctasctesmontosdescuento SET ccmdfechafin = now() 
  WHERE mesingreso <> case when date_part('day', current_date -30) > 15 then date_part('month', current_date) else date_part('month', current_date -30) end
      AND anioingreso <= case when date_part('day', current_date -30) > 15 then date_part('year', current_date) else date_part('year', current_date -30)  end
      AND nullvalue(ccmdfechafin);


/*Busco la ultima fecha de liquidacion de sueldos ques sea de tipo Sueldo y que este cerrada*/
select  into rliquidacion * from ca.liquidacion where    ( idliquidaciontipo=1 or  idliquidaciontipo=2)
        and not nullvalue(ca.liquidacion.lifechapago) order by idliquidacion desc limit 1;



resultado = true;
/*Ingreso los aportes de las personas que no fueron reportadas en el informe*/
OPEN alta FOR SELECT anioingreso,mesingreso,nrodoc,tipodoc,sum(importe)  as importe
	FROM dh21
	NATURAL JOIN ( --MaLaPi es solo para obtener el nrodoc,tipodoc
	SELECT legajosiu as nrolegajo,nrodoc,tipodoc FROM cargo GROUP BY legajosiu,nrodoc,tipodoc ) as t
	WHERE dh21.mesingreso >= case when date_part('day', current_date -30) > 15 then date_part('month', current_date) else date_part('month', current_date -30) end
	AND dh21.anioingreso >= case when date_part('day', current_date -30) > 15 then date_part('year', current_date) else date_part('year', current_date -30)  end
--      WHERE  dh21.mesingreso =11  AND dh21.anioingreso=2019
	AND dh21.nroconcepto = 357
  ---      AND nrodoc = '26331423'
        GROUP BY anioingreso,mesingreso,nrodoc,tipodoc

union
 
SELECT lianio as anioingreso,limes as mesingreso,tt.nrodoc,tt.tipodoc,sum(cemontofinal)  as importe 
	FROM ca.conceptoempleado
        NATURAL JOIN  ca.liquidacion
        NATURAL JOIN  ca.persona
	  JOIN (  
	SELECT legajosiu as nrolegajo,nrodoc,tipodoc FROM cargo GROUP BY legajosiu,nrodoc,tipodoc ) as tt on(penrodoc=nrodoc and idtipodocumento=tipodoc)
	WHERE ca.liquidacion.limes = rliquidacion.limes
	AND ca.liquidacion.lianio  = rliquidacion.lianio
        AND ca.conceptoempleado.idconcepto = 357
        GROUP BY anioingreso,mesingreso,nrodoc,tipodoc;
	
FETCH alta INTO elem;
WHILE  found LOOP
     SELECT INTO verifica * FROM ctasctesmontosdescuento 
                             WHERE nrodoc = elem.nrodoc 
                               AND tipodoc = elem.tipodoc 
                               AND mesingreso = elem.mesingreso
			       AND anioingreso = elem.anioingreso;

IF NOT FOUND THEN


     --MaLaPi 04-05-2022 Si la persona solicita no tener cta.cte, entonces no se debe generar el monto disponible en cta.cte
      SELECT INTO rexcentos * FROM ctacteexentos WHERE nrodoc = elem.nrodoc AND nullvalue(ccefechafin) AND not ccetienen;
      IF FOUND THEN 
         --MaLaPi 04-05-2022 Dejo la tupla en disponibles, pero con monto cero... de manera que quede marca que la UNC si nos informa y habilita
           elem.importe = 0;  
      END IF;
	

--20-03-19 se guarda el inicio y vigencia de lo permitido en cta cte. Si proceso en marzo el 357, corresponde a lo permitido a consumir durante el mes de abril, asi sucesivamente.
               INSERT INTO ctasctesmontosdescuento (nrodoc,tipodoc,ccmdimporte,mesingreso,anioingreso,ccmdvigenciainicio,ccmdvigenciafin)
               VALUES (elem.nrodoc,elem.tipodoc,elem.importe,elem.mesingreso,elem.anioingreso,concat(elem.anioingreso::text,'-',elem.mesingreso::text,'-','01')::date + interval '1 month',	concat(elem.anioingreso::text,'-',elem.mesingreso::text,'-','01')::date + interval '2 month'-interval '1 day');
END IF;

--KR 04-12-19 modifique pq estaba mal el concat, no se invocaba a la funcion correctamente por eso no habilitaba cuando correspondía la cta cte del afiliado. 
--- vas 080923 if (elem.nrodoc<> '23768510') then
PERFORM calcularmontosdisponibles(CONCAT('{nrodoc =',elem.nrodoc,',', 'tipodoc =', elem.tipodoc,'}'));
--- vas 080923  end if;

fetch alta into elem;
END LOOP;
CLOSE alta;

return resultado;

END;
$function$
