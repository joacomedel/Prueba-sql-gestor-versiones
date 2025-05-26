CREATE OR REPLACE FUNCTION public.test_belen_muchas_hojas_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
cursorctacblesumariza refcursor;
  rparam RECORD;
  rctacblesumariza RECORD; 
  rdatosctassumariza RECORD;
  respuesta varchar;
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

    -- Hace el calculo e insert en la tabla de los indices. 
     PERFORM contabilidad_balancecontable_mensual_indicexinflacion(concat('idejerciciocontable=',rparam.idejerciciocontable));

/*
        OPEN cursorctacblesumariza FOR SELECT *
                            FROM cuentacontablesumariza ccs
                            JOIN cuentascontables c ON (ccsnrocuentac=nrocuentac)
                            JOIN contabilidad_historico_indices_inflacion ON ( c.nrocuentac =  hiicuenta)
                            --WHERE 
                            --    ccsnrocuentac=10420
                            ORDER BY ccsnrocuentac asc
                            ;

        FETCH cursorctacblesumariza INTO rctacblesumariza;
        WHILE FOUND LOOP 

            SELECT INTO rdatosctassumariza 
            sum(hiihistorico) as hiihistorico, sum(hiihistorico_saldo) as hiihistorico_saldo, sum(hiisaldoinicialanual_saldo) as hiisaldoinicialanual_saldo, sum(hiisaldoinicialanual) as hiisaldoinicialanual, 

            sum(hiienero) as hiienero, sum(hiifebrero) as hiifebrero, sum(hiimarzo) as hiimarzo, sum(hiiabril) as hiiabril,
            sum(hiimayo) as hiimayo, sum(hiijunio) as hiijunio, sum(hiijulio) as hiijulio, sum(hiiagosto) as hiiagosto,
            sum(hiiseptiembre) as hiiseptiembre, sum(hiioctubre) as hiioctubre, sum(hiinoviembre) as hiinoviembre, sum(hiidiciembre) as hiidiciembre,

            sum(hiienero_saldo) as hiienero_saldo, sum(hiifebrero_saldo) as hiifebrero_saldo, sum(hiimarzo_saldo) as hiimarzo_saldo, sum(hiiabril_saldo) as hiiabril_saldo,
            sum(hiimayo_saldo) as hiimayo_saldo, sum(hiijunio_saldo) as hiijunio_saldo, sum(hiijulio_saldo) as hiijulio_saldo, sum(hiiagosto_saldo) as hiiagosto_saldo,
            sum(hiiseptiembre_saldo) as hiiseptiembre_saldo, sum(hiioctubre_saldo) as hiioctubre_saldo, sum(hiinoviembre_saldo) as hiinoviembre_saldo, sum(hiidiciembre_saldo) as hiidiciembre_saldo

            FROM cuentacontablesumariza ccs
            JOIN cuentascontables c ON ( c.nrocuentac = ANY(string_to_array(ccs.ccslistacuentas, ',')) )
            JOIN contabilidad_historico_indices_inflacion ON ( c.nrocuentac =  hiicuenta)
            WHERE not nullvalue(ccslistacuentas)
            AND ccsnrocuentac=rctacblesumariza.ccsnrocuentac
            GROUP BY ccs.ccsnrocuentac
            ORDER BY ccsnrocuentac asc
            ;

            UPDATE contabilidad_historico_indices_inflacion
            SET hiihistorico=rdatosctassumariza.hiihistorico, 
            hiihistorico_saldo=rdatosctassumariza.hiihistorico_saldo,
            hiisaldoinicialanual_saldo=rdatosctassumariza.hiisaldoinicialanual_saldo,
            hiisaldoinicialanual=rdatosctassumariza.hiisaldoinicialanual,


            hiienero=rdatosctassumariza.hiienero,
            hiifebrero=rdatosctassumariza.hiifebrero,
            hiimarzo=rdatosctassumariza.hiimarzo,
            hiiabril=rdatosctassumariza.hiiabril,
            hiimayo=rdatosctassumariza.hiimayo,
            hiijunio=rdatosctassumariza.hiijunio,
            hiijulio=rdatosctassumariza.hiijulio,
            hiiagosto=rdatosctassumariza.hiiagosto,
            hiiseptiembre=rdatosctassumariza.hiiseptiembre,
            hiioctubre=rdatosctassumariza.hiioctubre,
            hiinoviembre=rdatosctassumariza.hiinoviembre,
            hiidiciembre=rdatosctassumariza.hiidiciembre,


            hiienero_saldo=rdatosctassumariza.hiienero_saldo,
            hiifebrero_saldo=rdatosctassumariza.hiifebrero_saldo,
            hiimarzo_saldo=rdatosctassumariza.hiimarzo_saldo,
            hiiabril_saldo=rdatosctassumariza.hiiabril_saldo,
            hiimayo_saldo=rdatosctassumariza.hiimayo_saldo,
            hiijunio_saldo=rdatosctassumariza.hiijunio_saldo,
            hiijulio_saldo=rdatosctassumariza.hiijulio_saldo,
            hiiagosto_saldo=rdatosctassumariza.hiiagosto_saldo,
            hiiseptiembre_saldo=rdatosctassumariza.hiiseptiembre_saldo,
            hiioctubre_saldo=rdatosctassumariza.hiioctubre_saldo,
            hiinoviembre_saldo=rdatosctassumariza.hiinoviembre_saldo,
            hiidiciembre_saldo=rdatosctassumariza.hiidiciembre_saldo
            WHERE hiicuenta = rctacblesumariza.ccsnrocuentac;

        FETCH cursorctacblesumariza INTO rctacblesumariza;
        END LOOP;
*/


        CREATE TEMP TABLE temp_test_belen_muchas_hojas_contemporal_h1 AS (
            SELECT  
               CASE
                      WHEN hiigrupo = 'ACTIVO' THEN 1
                      WHEN hiigrupo = 'PASIVO' THEN 2
                      WHEN hiigrupo = 'PATRIMONIO NETO' THEN 3
                      WHEN hiigrupo = 'INGRESOS' THEN 4
                      WHEN hiigrupo = 'EGRESOS' THEN 5
                      ELSE 99 --Para los "MOVIMIENTO"
               END as orden
               ,

               hiigrupo,hiicuenta,hiidescripcioncuenta,
                CASE WHEN nullvalue(hiisaldoinicialanual_saldo) THEN 0 ELSE hiisaldoinicialanual_saldo END   as saldo_inicial_anual,

                CASE WHEN nullvalue(hiienero_saldo) THEN 0 ELSE hiienero_saldo END   as enero_saldo,

                CASE WHEN nullvalue(hiifebrero_saldo) THEN 0 ELSE hiifebrero_saldo END   as febrero_saldo,

                CASE WHEN nullvalue(hiimarzo_saldo) THEN 0 ELSE hiimarzo_saldo END   as marzo_saldo,

                CASE WHEN nullvalue(hiiabril_saldo) THEN 0 ELSE hiiabril_saldo END   as abril_saldo,
               
                CASE WHEN nullvalue(hiimayo_saldo) THEN 0 ELSE hiimayo_saldo END   as mayo_saldo,

                CASE WHEN nullvalue(hiijunio_saldo) THEN 0 ELSE hiijunio_saldo END   as junio_saldo,

                CASE WHEN nullvalue(hiijulio_saldo) THEN 0 ELSE hiijulio_saldo END   as julio_saldo,

                CASE WHEN nullvalue(hiiagosto_saldo) THEN 0 ELSE hiiagosto_saldo END   as agosto_saldo,

                CASE WHEN nullvalue(hiiseptiembre_saldo) THEN 0 ELSE hiiseptiembre_saldo END   as septiembre_saldo,

                CASE WHEN nullvalue(hiioctubre_saldo) THEN 0 ELSE hiioctubre_saldo END   as octubre_saldo,

                CASE WHEN nullvalue(hiinoviembre_saldo) THEN 0 ELSE hiinoviembre_saldo END   as noviembre_saldo,

                CASE WHEN nullvalue(hiidiciembre_saldo) THEN 0 ELSE hiidiciembre_saldo END   as diciembre_saldo,

                hiihistorico_saldo as historico_saldo

                ,'1-Orden#orden@2-Grupo#hiigrupo@3-Nrocuenta#hiicuenta@4-Descripcion Cuenta#hiidescripcioncuenta@5-Saldo Inicial Anual#saldo_inicial_anual@6-Enero Saldo#enero_saldo@7-Febrero Saldo#febrero_saldo@8-Marzo Saldo#marzo_saldo@9-Abril Saldo#abril_saldo@10-Mayo Saldo#mayo_saldo@11-Junio Saldo#junio_saldo@12-Julio Saldo#julio_saldo@13-Agosto Saldo#agosto_saldo@14-Septiembre Saldo#septiembre_saldo@15-Octubre Saldo#octubre_saldo@16-Noviembre Saldo#noviembre_saldo@17-Diciembre Saldo#diciembre_saldo@18-Historico Saldo#historico_saldo'::text as mapeocampocolumna

               FROM contabilidad_historico_indices_inflacion 
               LEFT JOIN multivac.mapeocuentascontables m ON (hiicuenta=nrocuentac)
               WHERE idejerciciocontable=rparam.idejerciciocontable

               ORDER BY  m.jerarquia
/*-- Ordena primero por Rubro y despues por nrocuentac
                      CASE
                             WHEN hiigrupo = 'ACTIVO' THEN 1
                             WHEN hiigrupo = 'PASIVO' THEN 2
                             WHEN hiigrupo = 'PATRIMONIO NETO' THEN 3
                             WHEN hiigrupo = 'INGRESOS' THEN 4
                             WHEN hiigrupo = 'EGRESOS' THEN 5
                             ELSE 6 --Para los "MOVIMIENTO"
                      END
                      , hiicuenta asc*/
        );


        CREATE TEMP TABLE temp_test_belen_muchas_hojas_contemporal_h2 AS (
            SELECT  
               CASE
                      WHEN hiigrupo = 'ACTIVO' THEN 1
                      WHEN hiigrupo = 'PASIVO' THEN 2
                      WHEN hiigrupo = 'PATRIMONIO NETO' THEN 3
                      WHEN hiigrupo = 'INGRESOS' THEN 4
                      WHEN hiigrupo = 'EGRESOS' THEN 5
                      ELSE 99 --Para los "MOVIMIENTO"
               END as orden
               ,

               hiigrupo,hiicuenta,hiidescripcioncuenta,
                CASE WHEN nullvalue(hiisaldoinicialanual) THEN 0 ELSE hiisaldoinicialanual END  as saldo_inicial_reexpresado,

                CASE WHEN nullvalue(hiienero) THEN 0 ELSE hiienero END  as enero_reexpresado,

                CASE WHEN nullvalue(hiifebrero) THEN 0 ELSE hiifebrero END  as febrero_reexpresado,

                CASE WHEN nullvalue(hiimarzo) THEN 0 ELSE hiimarzo END  as marzo_reexpresado,

                CASE WHEN nullvalue(hiiabril) THEN 0 ELSE hiiabril END  as abril_reexpresado,

                CASE WHEN nullvalue(hiimayo) THEN 0 ELSE hiimayo END  as mayo_reexpresado,

                CASE WHEN nullvalue(hiijunio) THEN 0 ELSE hiijunio END  as junio_reexpresado,       

                CASE WHEN nullvalue(hiijulio) THEN 0 ELSE hiijulio END  as julio_reexpresado,

                CASE WHEN nullvalue(hiiagosto) THEN 0 ELSE hiiagosto END  as agosto_reexpresado,

                CASE WHEN nullvalue(hiiseptiembre) THEN 0 ELSE hiiseptiembre END  as septiembre_reexpresado,

                CASE WHEN nullvalue(hiioctubre) THEN 0 ELSE hiioctubre END  as octubre_reexpresado,

                CASE WHEN nullvalue(hiinoviembre) THEN 0 ELSE hiinoviembre END  as noviembre_reexpresado,

                CASE WHEN nullvalue(hiidiciembre) THEN 0 ELSE hiidiciembre END  as diciembre_reexpresado,

               hiihistorico as historico_reexpresado
                ,'1-Orden#orden@2-Grupo#hiigrupo@3-Nrocuenta#hiicuenta@4-Descripcion Cuenta#hiidescripcioncuenta@5-Saldo Inicial Reexpresado#saldo_inicial_reexpresado@6-Enero Reexpresado#enero_reexpresado@7-Febrero Reexpresado#febrero_reexpresado@8-Marzo Reexpresado#marzo_reexpresado@9-Abril Reexpresado#abril_reexpresado@10-Mayo Reexpresado#mayo_reexpresado@11-Junio Reexpresado#junio_reexpresado@12-Julio Reexpresado#julio_reexpresado@13-Agosto Reexpresado#agosto_reexpresado@14-Septiembre Reexpresado#septiembre_reexpresado@15-Octubre Reexpresado#octubre_reexpresado@16-Noviembre Reexpresado#noviembre_reexpresado@17-Diciembre Reexpresado#diciembre_reexpresado@18-Historico Reexpresado#historico_reexpresado'::text as mapeocampocolumna


               FROM contabilidad_historico_indices_inflacion 
               LEFT JOIN multivac.mapeocuentascontables m ON (hiicuenta=nrocuentac)
               WHERE idejerciciocontable=rparam.idejerciciocontable

               ORDER BY  m.jerarquia
/*-- Ordena primero por Rubro y despues por nrocuentac
                      CASE
                             WHEN hiigrupo = 'ACTIVO' THEN 1
                             WHEN hiigrupo = 'PASIVO' THEN 2
                             WHEN hiigrupo = 'PATRIMONIO NETO' THEN 3
                             WHEN hiigrupo = 'INGRESOS' THEN 4
                             WHEN hiigrupo = 'EGRESOS' THEN 5
                             ELSE 6 --Para los "MOVIMIENTO"
                      END
                      , hiicuenta asc*/
        );


        CREATE TEMP TABLE temp_test_belen_muchas_hojas_contemporal_h3 AS (
            SELECT  
               CASE
                      WHEN hiigrupo = 'ACTIVO' THEN 1
                      WHEN hiigrupo = 'PASIVO' THEN 2
                      WHEN hiigrupo = 'PATRIMONIO NETO' THEN 3
                      WHEN hiigrupo = 'INGRESOS' THEN 4
                      WHEN hiigrupo = 'EGRESOS' THEN 5
                      ELSE 99 --Para los "MOVIMIENTO"
               END as orden
               ,

               hiigrupo,hiicuenta,
               CASE WHEN nullvalue(ccsnrocuentac)  THEN 'NO'  ELSE 'SI'  END as sumariza,
               hiidescripcioncuenta,
                CASE WHEN nullvalue(hiisaldoinicialanual_saldo) THEN 0 ELSE hiisaldoinicialanual_saldo END   as saldo_inicial_anual,
                CASE WHEN nullvalue(hiivalorsaldoinicialanual) THEN 0 ELSE hiivalorsaldoinicialanual END   as idx_0,
                CASE WHEN nullvalue(hiisaldoinicialanual) THEN 0 ELSE hiisaldoinicialanual END  as saldo_inicial_reexpresado,

                CASE WHEN nullvalue(hiienero_saldo) THEN 0 ELSE hiienero_saldo END   as enero_saldo,
                       CASE WHEN nullvalue(hiivalorenero) THEN 0 ELSE hiivalorenero END   as idx_01,
                       CASE WHEN nullvalue(hiienero) THEN 0 ELSE hiienero END  as enero_reexpresado,

                CASE WHEN nullvalue(hiifebrero_saldo) THEN 0 ELSE hiifebrero_saldo END   as febrero_saldo,
                       CASE WHEN nullvalue(hiivalorfebrero) THEN 0 ELSE hiivalorfebrero END   as idx_02,
                       CASE WHEN nullvalue(hiifebrero) THEN 0 ELSE hiifebrero END  as febrero_reexpresado,

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

                       hiihistorico_saldo as historico_saldo,
                       hiihistorico as historico_reexpresado
                --,'1-Orden#orden@2-Grupo#hiigrupo@3-Nrocuenta#hiicuenta@4-Descripcion Cuenta#hiidescripcioncuenta@5-Saldo Inicial Anual#saldo_inicial_anual@6-idx_0#idx_0@7-Saldo Inicial Reexpresado#saldo_inicial_reexpresado@8-Enero Saldo#enero_saldo@9-idx_01#idx_01@10-Enero Reexpresado#enero_reexpresado@11-Febrero Saldo#febrero_saldo@12-idx_02#idx_02@13-Febrero Reexpresado#febrero_reexpresado@14-Marzo Saldo#marzo_saldo@15-idx_03#idx_03@16-Marzo Reexpresado#marzo_reexpresado@17-Abril Saldo#abril_saldo@18-idx_04#idx_04@19-Abril Reexpresado#abril_reexpresado@20-Mayo Saldo#mayo_saldo@21-idx_05#idx_05@22-Mayo Reexpresado#mayo_reexpresado@23-Junio Saldo#junio_saldo@24-idx_06#idx_06@25-Junio Reexpresado#junio_reexpresado@26-Julio Saldo#julio_saldo@27-idx_07#idx_07@28-Julio Reexpresado#julio_reexpresado@29-Agosto Saldo#agosto_saldo@30-idx_08#idx_08@31-Agosto Reexpresado#agosto_reexpresado@32-Septiembre Saldo#septiembre_saldo@33-idx_09#idx_09@34-Septiembre Reexpresado#septiembre_reexpresado@35-Octubre Saldo#octubre_saldo@36-idx_10#idx_10@37-Octubre Reexpresado#octubre_reexpresado@38-Noviembre Saldo#noviembre_saldo@39-idx_11#idx_11@40-Noviembre Reexpresado#noviembre_reexpresado@41-Diciembre Saldo#diciembre_saldo@42-idx_12#idx_12@43-Diciembre Reexpresado#diciembre_reexpresado@44-Historico Saldo#historico_saldo@45-Historico Reexpresado#historico_reexpresado'::text as mapeocampocolumna
                ,'1-Orden#orden@2-Grupo#hiigrupo@3-Nrocuenta#hiicuenta@4-Sumariza#sumariza@5-Descripcion Cuenta#hiidescripcioncuenta@6-Saldo Inicial Anual#saldo_inicial_anual@7-idx_0#idx_0@8-Saldo Inicial Reexpresado#saldo_inicial_reexpresado@9-Enero Saldo#enero_saldo@10-idx_01#idx_01@11-Enero Reexpresado#enero_reexpresado@12-Febrero Saldo#febrero_saldo@13-idx_02#idx_02@14-Febrero Reexpresado#febrero_reexpresado@15-Marzo Saldo#marzo_saldo@16-idx_03#idx_03@17-Marzo Reexpresado#marzo_reexpresado@18-Abril Saldo#abril_saldo@19-idx_04#idx_04@20-Abril Reexpresado#abril_reexpresado@21-Mayo Saldo#mayo_saldo@22-idx_05#idx_05@23-Mayo Reexpresado#mayo_reexpresado@24-Junio Saldo#junio_saldo@25-idx_06#idx_06@26-Junio Reexpresado#junio_reexpresado@27-Julio Saldo#julio_saldo@28-idx_07#idx_07@29-Julio Reexpresado#julio_reexpresado@30-Agosto Saldo#agosto_saldo@31-idx_08#idx_08@32-Agosto Reexpresado#agosto_reexpresado@33-Septiembre Saldo#septiembre_saldo@34-idx_09#idx_09@35-Septiembre Reexpresado#septiembre_reexpresado@36-Octubre Saldo#octubre_saldo@37-idx_10#idx_10@38-Octubre Reexpresado#octubre_reexpresado@39-Noviembre Saldo#noviembre_saldo@40-idx_11#idx_11@41-Noviembre Reexpresado#noviembre_reexpresado@42-Diciembre Saldo#diciembre_saldo@43-idx_12#idx_12@44-Diciembre Reexpresado#diciembre_reexpresado@45-Historico Saldo#historico_saldo@46-Historico Reexpresado#historico_reexpresado'::text as mapeocampocolumna


               FROM contabilidad_historico_indices_inflacion 
               LEFT JOIN multivac.mapeocuentascontables m ON (hiicuenta=nrocuentac)
               LEFT JOIN cuentacontablesumariza ON (hiicuenta=ccsnrocuentac)

               WHERE idejerciciocontable=rparam.idejerciciocontable

               ORDER BY  m.jerarquia
/*-- Ordena primero por Rubro y despues por nrocuentac
                      CASE
                             WHEN hiigrupo = 'ACTIVO' THEN 1
                             WHEN hiigrupo = 'PASIVO' THEN 2
                             WHEN hiigrupo = 'PATRIMONIO NETO' THEN 3
                             WHEN hiigrupo = 'INGRESOS' THEN 4
                             WHEN hiigrupo = 'EGRESOS' THEN 5
                             ELSE 6 --Para los "MOVIMIENTO"
                      END
                      , hiicuenta asc*/

        );

      CREATE TEMP TABLE temp_test_belen_muchas_hojas_contemporal as (
        SELECT 'Datos_Completos' as titulohoja,'temp_test_belen_muchas_hojas_contemporal_h3' as nombretabla 
          UNION 
        SELECT 'Saldos' as titulohoja,'temp_test_belen_muchas_hojas_contemporal_h1' as nombretabla
          UNION 
        SELECT 'Saldos_Reexpresados' as titulohoja,'temp_test_belen_muchas_hojas_contemporal_h2' as nombretabla
      );
 
     respuesta = 'todook';
     
    
    
return respuesta;
END;
$function$
