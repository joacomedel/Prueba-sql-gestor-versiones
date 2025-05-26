CREATE OR REPLACE FUNCTION public.contabilidad_balancecontable_mensual_indicexinflacion(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
       rfiltros RECORD;
	   resp boolean;
	   i integer;
	   mes_letras  character varying;
	   mes_tope_numero integer;
	   el_sql character varying;
	   fecha_hasta character varying;
	   fecha_desde character varying;
	   parametro  character varying;
	   paramtro_func_ixi character varying;
	   ixi_valor double precision;
       el_sql_saldo_sys double precision;
	   idhixi bigint;
	   r_ejercicio RECORD;	  
	   
BEGIN


	-- SELECT * FROM contabilidad_balancecontable_mensual_indicexinflacion('idejerciciocontable=9');
	EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;
   
   --- bueso informacion del ejercicio contable
   SELECT INTO r_ejercicio * 
   FROM contabilidad_ejerciciocontable 
   WHERE idejerciciocontable =  rfiltros.idejerciciocontable;
   --- ecfechadesde <= current_date	AND ecfechahasta >= current_date;	
   -----r_ejercicio.idasientogenerico_apertura AND r_ejercicio.idcentroasientogenerico_apertura

    --- obtengo el mes hasta del ejericio contable que se esta analizando
    SELECT INTO mes_tope_numero EXTRACT(MONTH FROM r_ejercicio.ecfechahasta );
	
	 

	--- Actualizo la fecha de fincalizacion historico_indices_inflacion
 	
	UPDATE contabilidad_historico_indices_inflacion 
	SET hiifechageneracion_desde = now()
	WHERE nullvalue(hiifechageneracion_hasta);
 

    ---contabilidad_ejerciciocontable
    --- Limpio la ultima generacion del reporte vinculada al ejercicio contable
    DELETE FROM contabilidad_historico_indices_inflacion WHERE idejerciciocontable =r_ejercicio.idejerciciocontable ;
	--- Incorporo las cuentas configiguradas para reportar en indices por inflacion
	INSERT INTO contabilidad_historico_indices_inflacion (hiigrupo,hiicuenta,hiidescripcioncuenta,idejerciciocontable) 
	(SELECT case substring( Jerarquia,1,1)
			      when '1' then  'ACTIVO'
				  when '2' then 'PASIVO'
				  when '3' then 'PATRIMONIO NETO'
				  when '4' then 'INGRESOS'
	              when '5' then 'EGRESOS'
	              else 'MOVIMIENTO' end as  grupo
           ,nrocuentac,	desccuenta,r_ejercicio.idejerciciocontable
    FROM  cuentascontables 
    NATURAL JOIN multivac.mapeocuentascontables
	----WHERE ccreexpresar_ixi
	);

    RAISE NOTICE 'mes_tope_numero (%) fecha_desde (%)  fecha_hasta(%) >>>  ', mes_tope_numero , fecha_desde , fecha_hasta;
  	i=1; 
    for i in 1..mes_tope_numero LOOP
		--- calculo sumas y saldos 
		-- campos de la temporal idcuenta	codcuenta	descripcion	jerarquia	d_h	grupo	saldoanteriordebe	saldoanteriorhaber	debe	haber	saldoanterior	saldo	mapeocampocolumna
        
		RAISE NOTICE '<<< SE VA A CALCULAR MES   >>> % ', i;
		SELECT INTO fecha_desde 
	             concat( EXTRACT(year FROM r_ejercicio.ecfechadesde) --anio del ejercicio contable
				, '-' 
				,i
				,'-01'		 
				 ) ::date;
				 
				 
		SELECT INTO fecha_hasta 
	          ( concat ( CASE WHEN i = 12 THEN EXTRACT(year FROM r_ejercicio.ecfechadesde)+1
					ELSE EXTRACT(year FROM r_ejercicio.ecfechadesde) -- anio del ejercicio contable
					END  --anio
				, '-' 
				,CASE WHEN i = 12 THEN 1 
				 ELSE i+1 END --mes
				,'-01'		 
				 ) ::date - interval '1 day')::date;
		
		parametro =	concat( '{salidaExcelSigesconmultivac=true, fechaHasta=',fecha_hasta,', fechaDesde=',fecha_desde,', cuenta=TODAS, idcuenta=0, titulo=BALANCE CONTABLE (s..ges), salidaExcel=true, salidaExcelSiges=true, agrupa=false, nrofolio=0, modulo=Todos}'); 
        RAISE NOTICE 'Parametro temporal  >>> % ', parametro;
		SELECT INTO resp FROM contabilidad_balancecontable_contemporal(parametro );
		SELECT INTO mes_letras to_char(fecha_desde::date, 'tmmonth');
		paramtro_func_ixi = concat('{mes_numero=',i,',fecha_indice=',fecha_desde,'}');
		RAISE NOTICE 'Parametro paramtro_func_ixi  >>> % ', paramtro_func_ixi;
        --- buscar el asiento de apertura

               

               
         el_sql = concat( ' UPDATE contabilidad_historico_indices_inflacion 
                                  SET   
				--- saldo del año anterior
				
				hiisaldoinicialanual_saldo = 
					CASE WHEN ',i,'=1  THEN  
						CASE WHEN t.acid_h=''D'' THEN (t.acimonto)      --(-1* t.acimonto) Tere queria todo en positivo
						WHEN t.acid_h=''H'' THEN (-1* t.acimonto) END       --(t.acimonto) END
				 	ELSE round(hiisaldoinicialanual_saldo::numeric,2) END
				
				---- indice a aplicar al saldo inicial anual
	                     , hiivalorsaldoinicialanual = 
	                     	CASE WHEN ',i,'=1  THEN  
	                     		CASE WHEN t.ccreexpresar_ixi THEN  dar_contabilidad_indicexinflacion(''','{mes_numero=0 ,fecha_indice=',fecha_desde,'}',''')  
	                     		ELSE 1 END
					ELSE hiivalorsaldoinicialanual END
	                     
	                     ---- anual por el indice
				,hiisaldoinicialanual =  
					CASE WHEN ',i,'=1 THEN  
						CASE WHEN t.acid_h=''D'' THEN  round(( (t.saldoanterior - t.acimonto) * 
						CASE WHEN t.ccreexpresar_ixi THEN  dar_contabilidad_indicexinflacion(''','{mes_numero=0 ,fecha_indice=',fecha_desde,'}',''')  ELSE 1 END) ::numeric,2)
						WHEN t.acid_h=''H'' 
						THEN round(( (t.saldoanterior + t.acimonto) * 
						CASE  WHEN t.ccreexpresar_ixi THEN  dar_contabilidad_indicexinflacion(''','{mes_numero=0 ,fecha_indice=',fecha_desde,'}',''')  ELSE 1 END) ::numeric,2) 
						END
					ELSE  hiisaldoinicialanual END	   
	                  

				, hiivalor',mes_letras,' = CASE WHEN t.ccreexpresar_ixi THEN   dar_contabilidad_indicexinflacion(''',paramtro_func_ixi,''')  ELSE 1 END
                            
                            , hii',mes_letras,'  = 
                            	CASE WHEN (',i,'=1) THEN  
                            		((t.saldo-(CASE WHEN nullvalue(t.acimonto) THEN 0 ELSE t.acimonto END )) * 
                     			CASE WHEN t.ccreexpresar_ixi THEN   dar_contabilidad_indicexinflacion(''',paramtro_func_ixi,''')  
                     			ELSE 1 END)
                            		ELSE 
                            		t.saldo * 
                     			CASE WHEN t.ccreexpresar_ixi 
                     			THEN   dar_contabilidad_indicexinflacion(''',paramtro_func_ixi,''')  
	                            	ELSE 1 END 
					END 
                            
                            , hii',mes_letras,'_saldo =  
                            	CASE WHEN (',i,'=1) THEN  
				
						CASE WHEN t.acid_h=''D'' THEN (t.saldo-(CASE WHEN nullvalue(t.acimonto) THEN 0 ELSE t.acimonto END )) 
						WHEN t.acid_h=''H'' THEN (t.saldo+(CASE WHEN nullvalue(t.acimonto) THEN 0 ELSE t.acimonto END )) 
						WHEN nullvalue(t.acid_h) 
							THEN  t.saldo 
						END
		                     ELSE
						t.saldo  END 
                                                             

  			         FROM  (SELECT *
		                            FROM temp_contabilidad_balancecontable_contemporal 
						JOIN cuentascontables ON (nrocuentac=codcuenta )  ----- Calculo los saldos y saldos aplicado el indice 
		                            LEFT  JOIN (  SELECT  acimonto, nrocuentac, acid_h 
                                          FROM asientogenerico
                                          NATURAL JOIN asientogenericoitem  
                                          WHERE idasientogenerico =' ,r_ejercicio.idasientogenerico_apertura ,'
						AND idcentroasientogenerico = ', r_ejercicio.idcentroasientogenerico_apertura, '
                            	) as t2 ON(t2.nrocuentac = codcuenta)
                               
		      ) as t
                     
                     WHERE nullvalue(hiifechageneracion_hasta) 
						     AND t.codcuenta=contabilidad_historico_indices_inflacion.hiicuenta
						     AND  idejerciciocontable = ',r_ejercicio.idejerciciocontable );
               
               RAISE NOTICE 'SQL a ejecutar >>> % ', el_sql;
             -- descomentar  --- AND 	ccreexpresar_ixi) 
			 EXECUTE  el_sql;
		
		 
		
		--- ELIMINO La tabla temporal 
                DROP TABLE temp_contabilidad_balancecontable_contemporal;
		
end loop;	

-- Actualizo el importe total acumulado por cuenta
		
-- El historico reexpresado
/*UPDATE contabilidad_historico_indices_inflacion 
SET hiihistorico  = hiienero + hiifebrero +  hiimarzo + hiiabril + hiimayo + hiijunio + hiijulio + hiiagosto + hiiseptiembre + hiioctubre + hiinoviembre  +  hiidiciembre
WHERE  idejerciciocontable =r_ejercicio.idejerciciocontable;*/

UPDATE contabilidad_historico_indices_inflacion 
SET hiihistorico  =  CASE WHEN nullvalue(hiienero) THEN 0 ELSE hiienero END  + 
			CASE WHEN nullvalue(hiifebrero) THEN 0 ELSE hiifebrero END  +  
			CASE WHEN nullvalue(hiimarzo) THEN 0 ELSE hiimarzo END  + 
			CASE WHEN nullvalue(hiiabril) THEN 0 ELSE hiiabril END  + 
			CASE WHEN nullvalue(hiimayo) THEN 0 ELSE hiimayo END  + 
			CASE WHEN nullvalue(hiijunio) THEN 0 ELSE hiijunio END  + 
			CASE WHEN nullvalue(hiijulio) THEN 0 ELSE hiijulio END  + 
			CASE WHEN nullvalue(hiiagosto) THEN 0 ELSE hiiagosto END  + 
			CASE WHEN nullvalue(hiiseptiembre) THEN 0 ELSE hiiseptiembre END  + 
			CASE WHEN nullvalue(hiioctubre) THEN 0 ELSE hiioctubre END  + 
			CASE WHEN nullvalue(hiinoviembre) THEN 0 ELSE hiinoviembre END   +  
			CASE WHEN nullvalue(hiidiciembre) THEN 0 ELSE hiidiciembre END 
WHERE  idejerciciocontable =r_ejercicio.idejerciciocontable;

-- El historico de los saldos
/*UPDATE contabilidad_historico_indices_inflacion 
SET hiihistorico_saldo  = hiienero_saldo + hiifebrero_saldo +  hiimarzo_saldo + hiiabril_saldo + hiimayo_saldo + hiijunio_saldo + hiijulio_saldo + hiiagosto_saldo + hiiseptiembre_saldo + hiioctubre_saldo + hiinoviembre_saldo  +  hiidiciembre_saldo
WHERE  idejerciciocontable =r_ejercicio.idejerciciocontable;*/

UPDATE contabilidad_historico_indices_inflacion 
SET hiihistorico_saldo  =  CASE WHEN nullvalue(hiienero_saldo) THEN 0 ELSE hiienero_saldo END  + 
			CASE WHEN nullvalue(hiifebrero_saldo) THEN 0 ELSE hiifebrero_saldo END  +  
			CASE WHEN nullvalue(hiimarzo_saldo) THEN 0 ELSE hiimarzo_saldo END  + 
			CASE WHEN nullvalue(hiiabril_saldo) THEN 0 ELSE hiiabril_saldo END  + 
			CASE WHEN nullvalue(hiimayo_saldo) THEN 0 ELSE hiimayo_saldo END  + 
			CASE WHEN nullvalue(hiijunio_saldo) THEN 0 ELSE hiijunio_saldo END  + 
			CASE WHEN nullvalue(hiijulio_saldo) THEN 0 ELSE hiijulio_saldo END  + 
			CASE WHEN nullvalue(hiijulio_saldo) THEN 0 ELSE hiijulio_saldo END  + 
			CASE WHEN nullvalue(hiiseptiembre_saldo) THEN 0 ELSE hiiseptiembre_saldo END  + 
			CASE WHEN nullvalue(hiioctubre_saldo) THEN 0 ELSE hiioctubre_saldo END  + 
			CASE WHEN nullvalue(hiinoviembre_saldo) THEN 0 ELSE hiinoviembre_saldo END   +  
			CASE WHEN nullvalue(hiidiciembre_saldo) THEN 0 ELSE hiidiciembre_saldo END 
WHERE  idejerciciocontable =r_ejercicio.idejerciciocontable;

-- Falta calcular los historicos de los saldo
/*

SELECT  hiigrupo,hiicuenta,hiidescripcioncuenta,
        CASE WHEN nullvalue(hiisaldoinicialanual_saldo) THEN 0 ELSE hiisaldoinicialanual_saldo END   as saldo_inicial_anual,
        CASE WHEN nullvalue(hiivalorsaldoinicialanual) THEN 0 ELSE hiivalorsaldoinicialanual END   as idx_0,
        CASE WHEN nullvalue(hiisaldoinicialanual) THEN 0 ELSE hiisaldoinicialanual END  as saldo_inicial_reexpresado,

 CASE WHEN nullvalue(hiienero_saldo) THEN 0 ELSE hiienero_saldo END   as enero_saldo,
        CASE WHEN nullvalue(hiivalorenero) THEN 0 ELSE hiivalorenero END   as idx_01,
        CASE WHEN nullvalue(hiienero) THEN 0 ELSE hiienero END  as enero_reexpresado,

 CASE WHEN nullvalue(hiifebrero_saldo) THEN 0 ELSE hiifebrero_saldo END   as febrero_saldo,
        CASE WHEN nullvalue(hiivalorfebrero) THEN 0 ELSE hiivalorfebrero END   as idx_02,
        CASE WHEN nullvalue(hiifebrero) THEN 0 ELSE hiifebrero END  as febreo_reexpresado,

 CASE WHEN nullvalue(hiimarzo_saldo) THEN 0 ELSE hiimarzo_saldo END   as marzo_saldo,
        CASE WHEN nullvalue(hiivalormarzo) THEN 0 ELSE hiivalormarzo END   as idx_03,
        CASE WHEN nullvalue(hiimarzo) THEN 0 ELSE hiimarzo END  as marzo_reexpresado,

 CASE WHEN nullvalue(hiiabril_saldo) THEN 0 ELSE hiiabril_saldo END   as abril_saldo,
        CASE WHEN nullvalue(hiivalorabril) THEN 0 ELSE hiivalorabril END   as idx_04,
        CASE WHEN nullvalue(hiiabril) THEN 0 ELSE hiiabril END  as abril_reexpresado,

 
 CASE WHEN nullvalue(hiimayo_saldo) THEN 0 ELSE hiimayo_saldo END   as mayo_saldo,
        CASE WHEN nullvalue(hiivalormayo) THEN 0 ELSE hiivalormayo END   as idx_05,
        CASE WHEN nullvalue(hiimayo) THEN 0 ELSE hiimayo END  as mayo_reexpresado,
 

 CASE WHEN nullvalue(hiijunio_saldo) THEN 0 ELSE hiijunio_saldo END   as junio_saldo,
        CASE WHEN nullvalue(hiivalorjunio) THEN 0 ELSE hiivalorjunio END   as idx_06,
        CASE WHEN nullvalue(hiijunio) THEN 0 ELSE hiijunio END  as junio_reexpresado,
 

 CASE WHEN nullvalue(hiijulio_saldo) THEN 0 ELSE hiijulio_saldo END   as julio_saldo,
        CASE WHEN nullvalue(hiivalorjulio) THEN 0 ELSE hiivalorjulio END   as idx_07,
        CASE WHEN nullvalue(hiijulio) THEN 0 ELSE hiijulio END  as julio_reexpresado,

 CASE WHEN nullvalue(hiiagosto_saldo) THEN 0 ELSE hiiagosto_saldo END   as agosto_saldo,
        CASE WHEN nullvalue(hiivaloragosto) THEN 0 ELSE hiivaloragosto END   as idx_08,
        CASE WHEN nullvalue(hiiagosto) THEN 0 ELSE hiiagosto END  as agosto_reexpresado,

 CASE WHEN nullvalue(hiiseptiembre_saldo) THEN 0 ELSE hiiseptiembre_saldo END   as septiembre_saldo,
        CASE WHEN nullvalue(hiivalorseptiembre) THEN 0 ELSE hiivalorseptiembre END   as idx_09,
        CASE WHEN nullvalue(hiiseptiembre) THEN 0 ELSE hiiseptiembre END  as septiembre_reexpresado,

 CASE WHEN nullvalue(hiioctubre_saldo) THEN 0 ELSE hiioctubre_saldo END   as octubre_saldo,
        CASE WHEN nullvalue(hiivaloroctubre) THEN 0 ELSE hiivaloroctubre END   as idx_10,
        CASE WHEN nullvalue(hiioctubre) THEN 0 ELSE hiioctubre END  as octubre_reexpresado,

 CASE WHEN nullvalue(hiinoviembre_saldo) THEN 0 ELSE hiinoviembre_saldo END   as noviembre_saldo,
        CASE WHEN nullvalue(hiivalornoviembre) THEN 0 ELSE hiivalornoviembre END   as idx_11,
        CASE WHEN nullvalue(hiinoviembre) THEN 0 ELSE hiinoviembre END  as noviembre_reexpresado,

 CASE WHEN nullvalue(hiidiciembre_saldo) THEN 0 ELSE hiidiciembre_saldo END   as diciembre_saldo,
        CASE WHEN nullvalue(hiivalordiciembre) THEN 0 ELSE hiivalordiciembre END   as idx_12,
        CASE WHEN nullvalue(hiidiciembre) THEN 0 ELSE hiidiciembre END  as diciembre_reexpresado,

        hiihistorico
FROM contabilidad_historico_indices_inflacion 
WHERE idejerciciocontable=9

*/

return true;
END;

$function$
