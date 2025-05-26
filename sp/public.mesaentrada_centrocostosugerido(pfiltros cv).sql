CREATE OR REPLACE FUNCTION public.mesaentrada_centrocostosugerido(pfiltros character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$/* 
*/
DECLARE 
--RECORD
  rccsugerido RECORD;
  ractividad RECORD;
--VARIABLES
  vcantidadcc integer; 
  vporcentaje double precision;
BEGIN

IF iftableexists('temp_centrosugerido') THEN
   SELECT INTO rccsugerido * FROM temp_centrosugerido;
   IF FOUND THEN 
          SELECT INTO ractividad * from actividad where idactividad =rccsugerido.idactividad ;
          IF FOUND THEN 
           if (rccsugerido.idactividad = 2 or rccsugerido.idactividad = 10) then --Farmacia 
              UPDATE temp_centrosugerido set idcentrocosto = t.idcentrocosto, nombrecentrocosto=t.nombrecentrocosto , idporcentaje =100 ,acdescripcion=concat(ractividad.idactividad,'-', ractividad.acdescripcion)
              FROM  (select * from actividadcentrocosto natural join centrocosto WHERE accidactividad=rccsugerido.idactividad ) as t ;
           end if;
           if (rccsugerido.idactividad = 1 ) then --Obra Social 
              delete from temp_centrosugerido;
              insert into temp_centrosugerido(idcentrocosto,nombrecentrocosto,idporcentaje,importe,idactividad,acdescripcion) 
              SELECT idcentrocosto,nombrecentrocosto, accporcentaje,round(CAST ((rccsugerido.importe*accporcentaje/100) AS numeric),2) , 
              rccsugerido.idactividad, concat(ractividad.idactividad,'-', ractividad.acdescripcion)
              FROM actividadcentrocosto natural join centrocosto 
              WHERE accidactividad=rccsugerido.idactividad;
           end if;
           if (rccsugerido.idactividad = 3 ) then --Prorrateable 
              SELECT INTO vcantidadcc (SELECT COUNT(*) FROM actividadcentrocosto  WHERE accidactividad=rccsugerido.idactividad) ;
              vporcentaje = 100/vcantidadcc;
              UPDATE temp_centrosugerido set idcentrocosto = t.idcentrocosto, nombrecentrocosto=t.nombrecentrocosto , idporcentaje =vporcentaje, importe= round(CAST ((importe*vporcentaje/100) AS numeric),2) ,acdescripcion=concat(ractividad.idactividad,'-', ractividad.acdescripcion)
              FROM  (select * from actividadcentrocosto natural join centrocosto WHERE accidactividad=rccsugerido.idactividad ) as t ;
              insert into temp_centrosugerido(idcentrocosto,nombrecentrocosto,idporcentaje,importe,idactividad,acdescripcion) 
              SELECT idcentrocosto,nombrecentrocosto, 0.0, 0.0, 
              3, concat(ractividad.idactividad,'-', ractividad.acdescripcion)
              FROM centrocosto WHERE idcentrocosto <> 15 and ccactivo and idcentrocosto <> 0 ;
           end if;
           if (rccsugerido.idactividad = 4 ) then --Entretenimiento
              SELECT INTO vcantidadcc (SELECT COUNT(*) FROM actividadcentrocosto WHERE accidactividad=rccsugerido.idactividad) ;
              vporcentaje = 0;
              delete from temp_centrosugerido;
              insert into temp_centrosugerido(idcentrocosto,nombrecentrocosto,idporcentaje,importe,idactividad,acdescripcion) 
              SELECT idcentrocosto,nombrecentrocosto, vporcentaje, round(CAST ((rccsugerido.importe*vporcentaje/100) AS numeric),2) , 
              rccsugerido.idactividad, concat(ractividad.idactividad,'-', ractividad.acdescripcion)
              FROM actividadcentrocosto natural join centrocosto WHERE accidactividad=rccsugerido.idactividad;
           end if;
          END IF;
   END IF;
else 
   RAISE EXCEPTION 'R-001, No existen datos para sugerir información. ';
end if;

return '';
END;
$function$
