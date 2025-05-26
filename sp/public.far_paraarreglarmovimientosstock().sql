CREATE OR REPLACE FUNCTION public.far_paraarreglarmovimientosstock()
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
	baja CURSOR FOR 
select *, lstockinicial as posteriorbien from far_movimientostockitem 
natural join far_movimientostock 

natural join far_lote 
natural join far_articulo 
where idlote = 60345 
order by idmovimientostockitem;


/*SELECT * FROM far_movimientostockitem 
NATURAL JOIN (
SELECT idlote,msistockposterior as posteriorbien,msfecha as msfechabien 
FROM far_movimientostockitem 
NATURAL JOIN far_movimientostock
NATURAL JOIN (
SELECT  idlote,max(idmovimientostockitem) as idmovimientostockitem
FROM far_movimientostockitem 
WHERE not nullvalue(msistockposterior)
GROUP BY idlote ) as t
) as ultimostockbien
NATURAL JOIN far_movimientostock
WHERE nullvalue(msistockposterior) AND msfecha >= '2014-01-27' 
  AND msfecha >= msfechabien 
--AND (idlote = 67032 )
ORDER BY idlote,idmovimientostockitem;
*/

	elem RECORD;
	rtablas RECORD;
	resultado boolean;
        stockactual integer;
        stockanterior integer;
	stockposterior integer;
        idloteactual bigint;
        sigue boolean;
	
BEGIN

idloteactual = 0;
stockactual = -10000;
stockanterior = -10000;
stockposterior = -1000;
sigue = true;

--Para arreglar los campos de lote que estan vacios
/*UPDATE far_lote set lstock = x.msistockposterior
FROM (
SELECT * FROM far_movimientostockitem NATURAL JOIN (
SELECT  idlote,max(idmovimientostockitem) as idmovimientostockitem
FROM far_movimientostockitem 
NATURAL JOIN far_movimientostock
JOIN far_lote USING(idlote)
WHERE nullvalue(lstock) AND not nullvalue(msistockposterior)
GROUP BY idlote ) as t
) as x
where far_lote.idlote=x.idlote;
*/

OPEN baja;
FETCH baja INTO elem;
WHILE  found AND sigue LOOP

IF idloteactual <> elem.idlote THEN 
	stockactual = elem.posteriorbien;
        idloteactual = elem.idlote;
END IF;

IF nullvalue(elem.msisigno) THEN 
  IF elem.msdescripcion ilike '%Nueva Venta  Comprobante OV%' THEN 
     elem.msisigno = -1;
  END IF;
END IF;

IF not nullvalue(elem.msisigno) THEN 

IF  elem.msisigno > 0 THEN
 --Se incrementa
  stockanterior = stockactual;
  stockposterior = stockactual + elem.mscantidad;
  stockactual = stockactual + elem.mscantidad;
ELSE 
-- SE decrementa 
  stockanterior = stockactual;
  stockposterior = stockactual - elem.mscantidad;
  stockactual = stockactual - elem.mscantidad;
END IF;

UPDATE far_movimientostockitem SET msisigno =  elem.msisigno, msistockanterior = stockanterior, msistockposterior = stockposterior
WHERE idmovimientostockitem = elem.idmovimientostockitem;

ELSE
sigue =  false;

END IF;


fetch baja into elem;
END LOOP;
CLOSE baja;
return 0;

END;
$function$
