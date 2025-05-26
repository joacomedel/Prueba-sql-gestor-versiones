CREATE OR REPLACE FUNCTION public.turismo_reporteminutas_pagos_de_consumos(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       
	rfiltros RECORD;
	
BEGIN
   EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   --RAISE NOTICE 'another_func(%)',rfiltros.idturismoadmin;
CREATE TEMP TABLE temp_turismo_reporteminutas_pagos_de_consumos 
AS (
	SELECT fechaprestamo 
        ,tadescripcion
        ,idturismounidad
        ,tudescripcion  
 	,tipodoc
        ,nrodoc
        ,concat(apellido,',',nombres) as apenom
        ,imptotaldelconsumo
        ,ctopimportepagadototal
        ,infoOP
	,concat(idconsumoturismo,'-',idcentroconsumoturismo) as nroconsumo
	,concat(idprestamo,'-',idcentroprestamo) as codprestamo
	,ctdescuento
	,importeprestamo
,'1-Fecha Prestamo#fechaprestamo@2-Administrador#tadescripcion@3-Unidad Turismo#idturismounidad@4-Unidad Descripcion#tudescripcion@5-Tipodoc#tipodoc@6-Nrodoc#nrodoc@7-ApeyNom#apenom@8-TotalConsumo#imptotaldelconsumo@9-CtopImportePagadoTotal#ctopimportepagadototal@10-Info. OP#infoOP@11-Nro. Consumo#nroconsumo@12-Cod. Prestamo#codprestamo@13-Descuento#ctdescuento@14-importePrestamo#importeprestamo'::text as mapeocampocolumna


   /*    ,'1-Afiliado#apenom@2-Cod.Prestamo#codprestamo
      @3-Cod.Consumo#nroconsumo@4-Nro.Doc#nrodoc@5-TipoDoc#tipodoc@6-Importe Consumo#imptotaldelconsumo@7-Imp.Total Pag.#ctopimportepagadototal
 @8-Fecha Prestamo#fechaprestamo@9-Administrador#tadescripcion
 @10-InfoPago#infoop'::text as mapeocampocolumna*/

	
  FROM consumoturismo
  NATURAL JOIN  consumoturismoestado
  NATURAL JOIN (          SELECT idconsumoturismo, idcentroconsumoturismo , SUM(tuvimportesosunc*ctvcantdias) as imptotaldelconsumo,idturismoadmin,tadescripcion,tudescripcion
                          FROM consumoturismovalores
                          NATURAL JOIN turismounidadvalor
                          NATURAL JOIN turismounidad
                          NATURAL JOIN turismoadmin
                          WHERE  not ctvborrado and
				(idturismoadmin=rfiltros.idturismoadmin OR rfiltros.idturismoadmin = '0')
                          group by idconsumoturismo ,idcentroconsumoturismo,idturismoadmin, tadescripcion,tudescripcion
  ) as t
  NATURAL JOIN prestamo
  JOIN persona
  USING (tipodoc, nrodoc)
  LEFT JOIN (   SELECT idconsumoturismo,idcentroconsumoturismo,sum(ctopimportepagado) as ctopimportepagadototal,text_concatenar(concat('#OP Nro. ',nroordenpago,'-',idcentroordenpago, ' Importe : ',importetotal,' Fecha ',to_char(fechaingreso,'DD-MM-YYYY'),' Importe pag. MP: ',ctopimportepagado)) as infoOP
                FROM consumoturismoordenpago
                NATURAL JOIN ordenpago
                GROUP BY idconsumoturismo,idcentroconsumoturismo 

  ) as TOP using (idcentroconsumoturismo,idconsumoturismo)
WHERE fechaprestamo>= rfiltros.fechaprestamo_desde  and fechaprestamo <= rfiltros.fechaprestamo_hasta AND
idconsumoturismoestadotipos<>3  and nullvalue(ctefechafin)
order by fechaprestamo,apellido, idconsumoturismo,idcentroconsumoturismo




);
     

return true;
END;
$function$
