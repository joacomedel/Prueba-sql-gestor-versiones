CREATE OR REPLACE FUNCTION public.agregarmontosdedescuentos(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
/*
Ingresa la informacion de montos para descuentos disponilbles usando la informacion de la tabla dh21 con el concepto 357
para un afiliado en particular. Se llama desde el triguer de ctacteexentos. 
*/
DECLARE
	alta refcursor;
 	verifica RECORD;
        elem RECORD;
		rfiltros RECORD;
		rexcentos RECORD;
        resultado boolean;
		ventro boolean;
	
	
BEGIN

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

-- MaLaPi Doy de baja todos los activos total solo voy a levantar los que me sean iformados
UPDATE ctasctesmontosdescuento SET ccmdfechafin = now() 
  WHERE nullvalue(ccmdfechafin) AND nrodoc = rfiltros.nrodoc;
ventro = false;
resultado = true;
/*Ingreso los aportes de las personas que no fueron reportadas en el informe*/
OPEN alta FOR SELECT anioingreso,mesingreso,nrodoc,tipodoc,sum(importe)  as importe
	FROM dh21
	NATURAL JOIN ( --MaLaPi es solo para obtener el nrodoc,tipodoc
	SELECT legajosiu as nrolegajo,nrodoc,tipodoc FROM cargo GROUP BY legajosiu,nrodoc,tipodoc ) as t
	WHERE (dh21.mesingreso >= case when date_part('day', current_date -30) > 15 then date_part('month', current_date) else date_part('month', current_date -30) end
		   --MaLaPi 05-05-2022 Intento buscar la configuracion de 2 meses atras, para los casos donde son los primeros dias del mes y no se procesan los dh
		   OR dh21.mesingreso >= case when date_part('day', current_date -30) > 15 then date_part('month', current_date) else date_part('month', current_date -60) end)
	AND dh21.anioingreso >= case when date_part('day', current_date -30) > 15 then date_part('year', current_date) else date_part('year', current_date -30)  end
--      WHERE  dh21.mesingreso =11  AND dh21.anioingreso=2019
	AND dh21.nroconcepto = 357
    AND nrodoc = rfiltros.nrodoc
        GROUP BY anioingreso,mesingreso,nrodoc,tipodoc;
	
FETCH alta INTO elem;
WHILE  found LOOP
     SELECT INTO verifica * FROM ctasctesmontosdescuento 
                             WHERE nrodoc = elem.nrodoc 
                               AND tipodoc = elem.tipodoc 
                               AND mesingreso = elem.mesingreso
			       AND anioingreso = elem.anioingreso
				   AND ccmdimporte = elem.importe
				   AND nullvalue(ccmdfechafin);
ventro = true;
IF NOT FOUND THEN
		 --MaLaPi 04-05-2022 Si la persona solicita no tener cta.cte, entonces no se debe generar el monto disponible en cta.cte
      SELECT INTO rexcentos * FROM ctacteexentos WHERE nrodoc = elem.nrodoc AND nullvalue(ccefechafin) AND not ccetienen;
      IF FOUND THEN 
         --MaLaPi 04-05-2022 Dejo la tupla en disponibles, pero con monto cero... de manera que quede marca que la UNC si nos informa y habilita
           elem.importe = 0;
		   INSERT INTO ctasctesmontosdescuento (nrodoc,tipodoc,ccmdimporte,mesingreso,anioingreso,ccmdvigenciainicio,ccmdvigenciafin)
			VALUES (rfiltros.nrodoc,rfiltros.tipodoc,0,date_part('month', current_date),date_part('year', current_date),concat(date_part('year', current_date)::text,'-',date_part('month', current_date)::text,'-','01')::date + interval '1 month',	concat(date_part('year', current_date)::text,'-',date_part('month', current_date)::text,'-','01')::date + interval '2 month'-interval '1 day');
			PERFORM calcularmontosdisponibles(CONCAT('{nrodoc =',rfiltros.nrodoc,',', 'tipodoc =', rfiltros.tipodoc,'}'));
			--MaLaPi 05-05-2022 Hay que volverlo a llamar pues cuando el monto disponible queda en cero, el calcular no modifica el alerta
			PERFORM sys_generaralertactacteafiliado(rfiltros.nrodoc,rfiltros.tipodoc);

	  ELSE 
	  		--20-03-19 se guarda el inicio y vigencia de lo permitido en cta cte. Si proceso en marzo el 357, corresponde a lo permitido a consumir durante el mes de abril, asi sucesivamente.
               INSERT INTO ctasctesmontosdescuento (nrodoc,tipodoc,ccmdimporte,mesingreso,anioingreso,ccmdvigenciainicio,ccmdvigenciafin)
              VALUES (elem.nrodoc,elem.tipodoc,elem.importe,elem.mesingreso,elem.anioingreso,concat(elem.anioingreso::text,'-',elem.mesingreso::text,'-','01')::date + interval '1 month',	concat(elem.anioingreso::text,'-',elem.mesingreso::text,'-','01')::date + interval '2 month'-interval '1 day');
			  -- INSERT INTO ctasctesmontosdescuento (nrodoc,tipodoc,ccmdimporte,mesingreso,anioingreso,ccmdvigenciainicio,ccmdvigenciafin)
              -- VALUES (elem.nrodoc,elem.tipodoc,elem.importe,elem.mesingreso,elem.anioingreso,concat(elem.anioingreso::text,'-',elem.mesingreso::text,'-','01')::date + interval '1 month',	concat(elem.anioingreso::text,'-',elem.mesingreso::text,'-','01')::date + interval '3 month');
			   PERFORM calcularmontosdisponibles(CONCAT('{nrodoc =',elem.nrodoc,',', 'tipodoc =', elem.tipodoc,'}'));

      END IF;
END IF;

fetch alta into elem;
END LOOP;
CLOSE alta;
IF NOT ventro THEN 
INSERT INTO ctasctesmontosdescuento (nrodoc,tipodoc,ccmdimporte,mesingreso,anioingreso,ccmdvigenciainicio,ccmdvigenciafin)
VALUES (rfiltros.nrodoc,rfiltros.tipodoc,0,date_part('month', current_date),date_part('year', current_date),concat(date_part('year', current_date)::text,'-',date_part('month', current_date)::text,'-','01')::date + interval '1 month',	concat(date_part('year', current_date)::text,'-',date_part('month', current_date)::text,'-','01')::date + interval '2 month'-interval '1 day');
PERFORM calcularmontosdisponibles(CONCAT('{nrodoc =',rfiltros.nrodoc,',', 'tipodoc =', rfiltros.tipodoc,'}'));
--MaLaPi 05-05-2022 Hay que volverlo a llamar pues cuando el monto disponible queda en cero, el calcular no modifica el alerta
PERFORM sys_generaralertactacteafiliado(rfiltros.nrodoc,rfiltros.tipodoc);

END IF;

return resultado;

END;
$function$
