CREATE OR REPLACE FUNCTION ca.f_gestionfarmacia(integer, integer, integer, integer)
 RETURNS double precision
 LANGUAGE plpgsql
AS $function$/* New function body */
DECLARE
       elmonto DOUBLE PRECISION;
       montocataprendiz DOUBLE PRECISION;
       montoantiguedad DOUBLE PRECISION;
       horasjornada record;
       rdiastrabajados record;
BEGIN
       SELECT into horasjornada * 
       FROM ca.conceptoempleado
       NATURAL JOIN ca.concepto
       WHERE idpersona =$3
             AND idliquidacion = $1
             AND idconcepto = 1136;--Horas de la Jornada Semanal
 


--Busca el monto de la categoria 12 -   Cadetes -  Aprendiz Ayudante
       SELECT INTO  montocataprendiz camonto
       FROM  ca.categoriatipoliquidacion
       NATURAL JOIN ca.categoriatipo
       WHERE idcategoria =12 and idcategoriatipo =1 and idliquidaciontipo=2;


       SELECT INTO   montoantiguedad (ceporcentaje * cemonto)
       FROM ca.conceptoempleado
       WHERE idpersona =$3
              AND idliquidacion = $1
              AND idconcepto = 1050 ;--Antiguedad Artículo 15

       if nullvalue( montoantiguedad)  THEN montoantiguedad =0;  END IF;
       if nullvalue( montocataprendiz)  THEN montocataprendiz =0;  END IF;


       SELECT INTO rdiastrabajados * --busco los dias trabajados
       FROM ca.conceptoempleado
       WHERE idpersona =$3
             AND idliquidacion = $1
             AND idconcepto = 998 ;--Dias Trabajados




/*si tiene jornada reducida se calcula el proporcional*/
       elmonto = montoantiguedad + (montocataprendiz*(horasjornada.cemonto)/(horasjornada.ceporcentaje));
       

 
    ---Dani agrego 11102023  por pedido de JE debe calcular el proporcional de todos los conceptos de tipo suplemento
    IF (rdiastrabajados.ceporcentaje<30) THEN -- trabajo menos de 30 dias
                elmonto=(elmonto/30)*rdiastrabajados.ceporcentaje;

    END IF;
 


return 	elmonto;
END;
$function$
