CREATE OR REPLACE FUNCTION public.afip_txt_f1357(character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$/* Funcion F. 1357 Versión 8 */
DECLARE
       rinfo_cabecera refcursor;  ---lpad(rinfo.remuneracion_no_alcanzada ,15,'@')  ''; --- Long 15  
       r_iva_comp RECORD;
       cant integer;
       rdata record;

--Variables Registro Cabecera
       tipo_registro_cabecera character varying;
       cuit_agente_retencion character varying;
       periodo_informado character varying;
       secuencia character varying;
       codigo_de_impuesto character varying;
       codigo_de_concepto character varying;
       numero_formulario character varying;
       tipo_presentacion character varying;
       version_sistema character varying;

--Variables Datos Trabajador Reg Nº2
       tipo_registro_reg2 character varying;
       cuil_empleado character varying; 
       periodo_trabajado_desde character varying;
       periodo_trabajado_hasta character varying;
       meses character varying;
       beneficio character varying;
       larga_distancia character varying;
       benef_promocional character varying;
       benef_ley_27424 character varying;
       regimen_ley27718 character varying;
       regimen_teletrabajo_ley27555  character varying;
       es_militar_ley19101  character varying;
       transporte_terrestre  character varying;
       
--Variables Datos Remuneraciones Reg Nº3
       
       tipo_registro_reg3 character varying;
       remuneracion_bruta_gravada  character varying;
       retribuciones_no_habituales_gravadas  character varying;
       sac_primera_cuota_gravado  character varying;
       sac_segunda_cuota_gravado  character varying;
       horas_extras_gravadas  character varying;
       movilidad_viaticos_rem_gravada  character varying;
       personal_doc_mat_didact_gravado  character varying;
       remuneracion_no_alcanzada  character varying;
       remuneracion_exenta_horas_extra  character varying;
       movilidad_viaticos_rem_exenta  character varying;
       personal_doc_mat_didact_exento  character varying;
       remuneracion_otros_empleos_brut_gravada  character varying;
       remuneracion_otros_empleos_retribuciones_no_habituales_gravadas  character varying;
       remuneracion_otros_empleos_sac_primera_cuota_gravado  character varying;
       remuneracion_otros_empleos_sac_segunda_cuota_gravado  character varying;
       remuneracion_otros_empleos_horas_extras_gravadas  character varying;
       remuneracion_otros_empleos_movilidad_viaticos_gravada  character varying;
       remuneracion_otros_empleos_personal_doc_mat_didact_gravado  character varying;
       remuneracion_otros_empleos_remuneracion_no_alcanzada  character varying;
       remuneracion_otros_empleos_remuneracion_exenta_horas_extra  character varying;
       remuneracion_otros_empleos_movilidad_viaticos_exenta  character varying;
       remuneracion_otros_empleos_personal_doc_mat_didact_exento  character varying;
       remuneracion_gravada  character varying;
       remuneracion_no_gravada  character varying;
       total_remuneraciones  character varying;
       retribuciones_no_habituales_exentas  character varying;
       sac_primera_cuota_exenta  character varying;
       sac_segunda_cuota_exenta  character varying;
       ajustes_periodos_anteriores_rem_gravadas  character varying;
       ajustes_periodos_anteriores_rem_exentas  character varying;
       otros_empleos_retrib_no_habituales_exentas  character varying;
       otros_empleos_sac_primera_cuota_exenta  character varying;       
       otros_empleos_sac_segunda_cuota_exenta  character varying;
       otros_empleos_ajustes_periodos_anteriores_rem_gravadas  character varying;
       otros_empleos_ajustes_periodos_anteriores_rem_exentas  character varying;
       remuneracion_exenta_ley27718  character varying;
       otros_empleos_remuneracion_exenta_ley27718  character varying;      
       bonos_productividad_gravados  character varying;
       fallos_caja_gravados  character varying;
       conceptos_similar_naturaleza_gravados  character varying;
       bonos_productividad_exentos  character varying;
       fallos_caja_exentos  character varying;
       conceptos_similar_naturaleza_exentos  character varying;
       compensacion_gastos_teletrabajo_exentos  character varying;
       personal_militar_ley19101_exentos  character varying;
       otros_empleos_bonos_productividad_gravados  character varying;
       otros_empleos_fallos_caja_gravados  character varying;
       otros_empleos_conceptos_similar_naturaleza_gravados  character varying;
       otros_empleos_bonos_productividad_exentos  character varying;
       otros_empleos_fallos_caja_exentos  character varying;
       otros_empleos_conceptos_similar_naturaleza_exentos  character varying;
       otros_empleos_compensacion_gastos_teletrabajo_exentos  character varying;
       otros_empleos_personal_militar_ley19101_exentos  character varying;
       cantidad_bonos_productividad  character varying;
       cantidad_fallos_de_caja   character varying;
       cant_conceptos_similar_naturaleza  character varying;
       otros_empleos_cant_bonos_productividad  character varying;
       otros_empleos_cantidad_fallos_de_caja  character varying;
       otros_empleos_cant_conceptos_similar_naturaleza  character varying;
       movilidad_remuneracion_gravada  character varying;
       viaticos_remuneracion_gravada  character varying;
       compensacion_analogos_remuneracion_gravada  character varying;
       remuneracion_otros_empleos_movilidad_remuneracion_gravada  character varying;
       remuneracion_otros_empleos_viaticos_remuneracion_gravada  character varying;
       remuneracion_otros_empleos_compensacion_analogos_remuneracion_gravada  character varying;
       

--Variables Datos Remuneraciones Reg Nº4

       tipo_registro_reg4  character varying;
       ap_jubilatorio_retiro_pens character varying;
       otros_empleos_ap_jubilatorio_retiro_pens character varying;
       aportes_obra_social character varying;
       otros_empleos_aportes_obra_social character varying;
       cuota_sindical character varying;
       otros_empleos_cuota_sindical character varying;
       cuotas_medico_asistenciales character varying;
       primas_seguro_caso_muerte character varying;
       seguros_muerte_mixtos_ssn character varying;
       seguros_retiro_privados character varying;
       adquisicion_cuotapartes_fci_fines_retiro character varying;
       gastos_sepelio character varying;
       gastos_amort_viajantes_comercio character varying;
       donac_fiscos character varying;
       descuentos_oblig_por_ley character varying;
       honorarios_serv_asist_sanitaria_medica_paramedica character varying;
       intereses_cred_hipot character varying;
       ap_cap_soc_fondo_riesgo character varying;
       otras_deducciones_cajas_complementarias_prevision character varying;
       alquileres_inmuebles_casa character varying;
       empleados_servicio_domestico character varying;
       gastos_mov_viaticos_abonados_empleador character varying;
       indumentaria_caracter_obligatorio character varying;
       otras_deducciones character varying;
       total_deducciones_generales character varying;
       otras_deducciones_aportes_jubilaciones character varying;
       otras_deducciones_cajas_profesionales character varying;
       otras_deducciones_actores character varying;
       otras_deducciones_fondos_compensadores_prevision character varying;
       servicios_educativos_herramientas_destinadas character varying;
       gastos_mov_abonados_empleador character varying;
       gastos_viaticos_abonados_empleador character varying;
       compensacion_analoga character varying;
       cantidad_compensacion_analoga character varying;

--Variables Datos Remuneraciones Reg Nº5

       tipo_registro_reg5 character varying;
       ganancia_no_imponible character varying;
       deduccion_especial character varying;
       deduccion_especifica character varying;
       coyuge_union_convivencial character varying;
       cant_hijos_hijastros_al_50 character varying;
       hijos_hijastros character varying;
       total_cargas_familia character varying;
       total_deducciones_art_30 character varying;
       remuneracion_sujeta_impuesto_ex_ley27541 character varying;
       deduccion_inc_a_art_46_ley27541_gni character varying;
       deduccion_inc_c_art_46_ley27541_de character varying;
       remuneracion_sujeta_a_impuesto character varying;
       cantidad_hijos_incapacitados_para_trabajo_al_50 character varying;
       hijos_incapacitados_para_trabajo character varying;
       deduccion_especial_primera_parte_penultimo_parrafo_inciso_c_art_30_ley_gravamen character varying;
       deduccion_especial_segunda_parte_penultimo_parrafo_inciso_c_art_30_ley_gravamen character varying;
       cant_hijos_hijastros_al_100 character varying;
       cantidad_hijos_incapacitados_para_trabajo_al_100 character varying;
       cantidad_hijos_hijastros_educacion_al_50 character varying;
       cantidad_hijos_hijastros_educacion_al_100 character varying;

--Variables Datos Remuneraciones Reg Nº6       

       tipo_registro_reg6 character varying;
       alicuota_art_94_ley_ganancias character varying;
       alicuota_aplicable character varying;
       impuesto_determinado character varying;
       impuesto_retenido character varying;
       pagos_a_cuanta_total character varying;
       saldo character varying;
       pagos_a_cuenta_creditos_debitos character varying;
       pagos_a_cuenta_percepciones_reten_aduaneras character varying;
       pagos_a_cuenta_resol_afip_3819_cancelaciones_efectivo_agen_turismo character varying;
       pagos_a_cuenta_bono_ley_27424 character varying;
       pagos_a_cuenta_ley27541_art_35_inc_a character varying;
       pagos_a_cuenta_ley27541_art_35_inc_b character varying;
       pagos_a_cuenta_ley27541_art_35_inc_c character varying;
       pagos_a_cuenta_ley27541_art_35_inc_d character varying;
       pagos_a_cuenta_ley27541_art_35_inc_e character varying;
       pagos_a_cuenta_impuesto_creditos_debitos_fondos_propios_terceros character varying;
       pagos_a_cuenta_resolucion_afip_servicios_transporte_destino_fuera_pais character varying;

       
BEGIN
     
     EXECUTE sys_dar_filtros($1) INTO rdata;
----------------------------------------------
---    Registro Cabecera   --- INFO EMPLEADOR SOSUNC
----------------------------------------------
      tipo_registro_cabecera = '01'         ;     ---Valor fijo (01) long 2
      cuit_agente_retencion = '30590509643';  ---Valor fijo () long 11
      periodo_informado = '202401' ; --- Long 6 Formato presentación Anual = AAAA00 / Resto de presentaciones =AAAAMM
      secuencia = '00'             ; --- 00 = Original / Rectificativas en forma secuencial 01, etc.) Long 2
      codigo_de_impuesto = '0103'  ; --- Valor fijo (0103)Long 4
      codigo_de_concepto = '215'   ; --- Valor fijo (215)  Long 3
      numero_formulario = '1357'   ; --- Valor Fijo (1357 )Long 4
      tipo_presentacion = '1'      ; --- Tipo según tabla 1(1-ANUAL,2-FINAL,3-INFORMATIVA,4-ANUAL → DISTRACTO ENE - MAR) Long 1
      version_sistema = '00800'    ; --- Valor fijo (00800) Long 5
      

     -- 1 - Elimino los  registros generados para esa liquidacion iva
     DELETE  FROM afip_F1357 WHERE  idperiodofiscal = rdata.idperiodofiscal;

----------------------------------------------
--- Detalles del Registro Datos del Trabajador (Reg. Tipo 02)
----------------------------------------------

      tipo_registro_reg2 = '02'; --- Valor fijo (02)Long 2
      cuil_empleado = '12123456789'; --- CUIL Long 11
      periodo_trabajado_desde = '20240301'; --- (Formato AAAAMMDD) Long 8
      periodo_trabajado_hasta =  '20240330'; --- (Formato AAAAMMDD) Long 8
      meses = '01'; --- formato 00 Long 2
      beneficio = '2'; --- 
/* Tabla 2 (1- SIN BENEFICIO, 2- ZONA PATAGÓNICA – INCREMENTO DEL 22%, 3- J/P/R - Deducción especifica equivalente a ocho (8) veces la suma de los haberes mínimos  garantizados, definidos en el artículo 125 de la ley 24.241 y sus mod. y comp., 4- JUBILADO ZONA PATAGÓNICA) Long 2 */
      larga_distancia = '0'; --- Numérico -( 1 = Sí/ 0 = No) Long 1
      benef_promocional = '0'; --- Valor fijo (0) Long 1
      benef_ley_27424 = '0'; --- Numérico -( 1 = Sí/ 0 = No) Long 1
      regimen_ley27718 = '0'; --- Numérico -( 1 = Sí/ 0 = No) Long 1
      regimen_teletrabajo_ley27555 = '0'; --- Numérico -( 1 = Sí/ 0 = No) Long 1
      es_militar_ley19101 = '0'; --- Numérico -( 1 = Sí/ 0 = No) Long 1
      transporte_terrestre = '0'; --- Numérico -( 1 = Sí/ 0 = No) Long 1

----------------------------------------------
--- Detalles del Registro Remuneraciones del Trabajador (Reg. Tipo 03)
----------------------------------------------

       tipo_registro_reg3 = '03'; --- Valor fijo (03)Long 2  
       remuneracion_bruta_gravada = ''; --- Long 15
       retribuciones_no_habituales_gravadas = ''; --- Long 15
       sac_primera_cuota_gravado = ''; --- Long 15 
       sac_segunda_cuota_gravado = ''; --- Long 15
       horas_extras_gravadas = ''; --- Long 15 
       movilidad_viaticos_rem_gravada = '0'; --- Valor fijo (0) Long 1 
       personal_doc_mat_didact_gravado = ''; --- Long 15 
       remuneracion_no_alcanzada = ''; --- Long 15  
       remuneracion_exenta_horas_extra = ''; --- Long 15  
       movilidad_viaticos_rem_exenta  = '0'; --- Valor fijo (0) Long 1
       personal_doc_mat_didact_exento = ''; --- Long 15 
       remuneracion_otros_empleos_brut_gravada = ''; --- Long 15  
       remuneracion_otros_empleos_retribuciones_no_habituales_gravadas = ''; --- Long 15  
       remuneracion_otros_empleos_sac_primera_cuota_gravado = ''; --- Long 15  
       remuneracion_otros_empleos_sac_segunda_cuota_gravado = ''; --- Long 15  
       remuneracion_otros_empleos_horas_extras_gravadas  = ''; --- Long 15 
       remuneracion_otros_empleos_movilidad_viaticos_gravada = '0'; --- Valor fijo (0) Long 1
       remuneracion_otros_empleos_personal_doc_mat_didact_gravado = ''; --- Long 15  
       remuneracion_otros_empleos_remuneracion_no_alcanzada = ''; --- Long 15  
       remuneracion_otros_empleos_remuneracion_exenta_horas_extra = ''; --- Long 15  
       remuneracion_otros_empleos_movilidad_viaticos_exenta = '0'; --- Valor fijo (0) Long 1
       remuneracion_otros_empleos_personal_doc_mat_didact_exento = ''; --- Long 15  
       remuneracion_gravada = ''; --- Long 15  
       remuneracion_no_gravada = ''; --- Long 15  
       total_remuneraciones = ''; --- Long 17 
       retribuciones_no_habituales_exentas = ''; --- Long 15  
       sac_primera_cuota_exenta = ''; --- Long 15  
       sac_segunda_cuota_exenta = ''; --- Long 15  
       ajustes_periodos_anteriores_rem_gravadas = ''; --- Long 15 
       ajustes_periodos_anteriores_rem_exentas = ''; --- Long 15  
       otros_empleos_retrib_no_habituales_exentas = ''; --- Long 15 
       otros_empleos_sac_primera_cuota_exenta = ''; --- Long 15 
       otros_empleos_sac_segunda_cuota_exenta = ''; --- Long 15 
       otros_empleos_ajustes_periodos_anteriores_rem_gravadas = ''; --- Long 15 
       otros_empleos_ajustes_periodos_anteriores_rem_exentas = ''; --- Long 15 
       remuneracion_exenta_ley27718 = ''; --- Long 15  
       otros_empleos_remuneracion_exenta_ley27718 = ''; --- Long 15        
       bonos_productividad_gravados = ''; --- Long 15 
       fallos_caja_gravados = ''; --- Long 15 
       conceptos_similar_naturaleza_gravados = ''; --- Long 15 
       bonos_productividad_exentos = ''; --- Long 15 
       fallos_caja_exentos = ''; --- Long 15 
       conceptos_similar_naturaleza_exentos = ''; --- Long 15 
       compensacion_gastos_teletrabajo_exentos = ''; --- Long 15 
       personal_militar_ley19101_exentos  = ''; --- Long 15 
       otros_empleos_bonos_productividad_gravados = ''; --- Long 15 
       otros_empleos_fallos_caja_gravados = ''; --- Long 15 
       otros_empleos_conceptos_similar_naturaleza_gravados = ''; --- Long 15 
       otros_empleos_bonos_productividad_exentos = ''; --- Long 15 
       otros_empleos_fallos_caja_exentos = ''; --- Long 15 
       otros_empleos_conceptos_similar_naturaleza_exentos = ''; --- Long 15 
       otros_empleos_compensacion_gastos_teletrabajo_exentos = ''; --- Long 15 
       otros_empleos_personal_militar_ley19101_exentos = ''; --- Long 15 
       cantidad_bonos_productividad = ''; --- Long 2
       cantidad_fallos_de_caja = ''; --- Long 2
       cant_conceptos_similar_naturaleza = ''; --- Long 2
       otros_empleos_cant_bonos_productividad = ''; --- Long 2
       otros_empleos_cantidad_fallos_de_caja = ''; --- Long 2
       otros_empleos_cant_conceptos_similar_naturaleza = ''; --- Long 2
       movilidad_remuneracion_gravada = ''; --- Long 15 
       viaticos_remuneracion_gravada = ''; --- Long 15 
       compensacion_analogos_remuneracion_gravada = ''; --- Long 15 
       remuneracion_otros_empleos_movilidad_remuneracion_gravada = ''; --- Long 15 
       remuneracion_otros_empleos_viaticos_remuneracion_gravada = ''; --- Long 15 
       remuneracion_otros_empleos_compensacion_analogos_remuneracion_gravada = ''; --- Long 15 
       

----------------------------------------------
--- Detalles del Registro Deducciones del Trabajador (Reg. Tipo 04)
----------------------------------------------

       tipo_registro_reg4 = '04'; --- Valor fijo (04)Long 2
       ap_jubilatorio_retiro_pens  = ''; --- Long 15 
       otros_empleos_ap_jubilatorio_retiro_pens = ''; --- Long 15 
       aportes_obra_social = ''; --- Long 15 
       otros_empleos_aportes_obra_social = ''; --- Long 15 
       cuota_sindical = ''; --- Long 15 
       otros_empleos_cuota_sindical = ''; --- Long 15 
       cuotas_medico_asistenciales = ''; --- Long 15 
       primas_seguro_caso_muerte = ''; --- Long 15 
       seguros_muerte_mixtos_ssn = ''; --- Long 15 
       seguros_retiro_privados = ''; --- Long 15 
       adquisicion_cuotapartes_fci_fines_retiro = ''; --- Long 15 
       gastos_sepelio = ''; --- Long 15 
       gastos_amort_viajantes_comercio = ''; --- Long 15 
       donac_fiscos = ''; --- Long 15 
       descuentos_oblig_por_ley = ''; --- Long 15 
       honorarios_serv_asist_sanitaria_medica_paramedica = ''; --- Long 15 
       intereses_cred_hipot = ''; --- Long 15 
       ap_cap_soc_fondo_riesgo = ''; --- Long 15 
       otras_deducciones_cajas_complementarias_prevision = ''; --- Long 15 
       alquileres_inmuebles_casa = ''; --- Long 15 
       empleados_servicio_domestico = ''; --- Long 15 
       gastos_mov_viaticos_abonados_empleador = '0'; ---Valor fijo(0) Long 1
       indumentaria_caracter_obligatorio = ''; --- Long 15  
       otras_deducciones = ''; --- Long 15 
       total_deducciones_generales = ''; --- Long 17
       otras_deducciones_aportes_jubilaciones = ''; --- Long 15 
       otras_deducciones_cajas_profesionales = ''; --- Long 15 
       otras_deducciones_actores = ''; --- Long 15 
       otras_deducciones_fondos_compensadores_prevision = ''; --- Long 15 
       servicios_educativos_herramientas_destinadas = ''; --- Long 15 
       gastos_mov_abonados_empleador = ''; --- Long 15 
       gastos_viaticos_abonados_empleador = ''; --- Long 15 
       compensacion_analoga = ''; --- Long 15 
       cantidad_compensacion_analoga = ''; --- Long 2

----------------------------------------------
--- Detalles del Registro Deducciones Art. 30 (Reg. Tipo 05)
----------------------------------------------

       tipo_registro_reg5 = '05'; --- Valor fijo(05)Long 2
       ganancia_no_imponible = ''; --- Long 15
       deduccion_especial = ''; --- Long 15
       deduccion_especifica = ''; --- Long 15
       coyuge_union_convivencial = ''; --- Long 15
       cant_hijos_hijastros_al_50 = ''; --- Long 2
       hijos_hijastros = ''; --- Long 15
       total_cargas_familia = ''; --- Long 15
       total_deducciones_art_30 = ''; --- Long 15
       remuneracion_sujeta_impuesto_ex_ley27541 ='0'; --- Valor fijo (0) Long 1
       deduccion_inc_a_art_46_ley27541_gni ='0'; --- Valor fijo (0) Long 1
       deduccion_inc_c_art_46_ley27541_de ='0'; --- Valor fijo (0) Long 1
       remuneracion_sujeta_a_impuesto ='0'; --- Valor fijo (0) Long 15
       cantidad_hijos_incapacitados_para_trabajo_al_50 = ''; --- Long 2
       hijos_incapacitados_para_trabajo = ''; --- Long 15
       deduccion_especial_primera_parte_penultimo_parrafo_inciso_c_art_30_ley_gravamen = ''; --- Long 15
       deduccion_especial_segunda_parte_penultimo_parrafo_inciso_c_art_30_ley_gravamen = ''; --- Long 15
       cant_hijos_hijastros_al_100  = ''; --- Long 2
       cantidad_hijos_incapacitados_para_trabajo_al_100 = ''; --- Long 2
       cantidad_hijos_hijastros_educacion_al_50 = ''; --- Long 2
       cantidad_hijos_hijastros_educacion_al_100 = ''; --- Long 2

----------------------------------------------
--- Detalles del Registro Calculo del Impuesto (Reg. Tipo 06)
----------------------------------------------

       tipo_registro_reg6 = '06'; --- Valor fijo (06)Long 2
       alicuota_art_94_ley_ganancias = ''; --- Long 1
       alicuota_aplicable = ''; --- Long 1
       impuesto_determinado = ''; --- Long 15
       impuesto_retenido = ''; --- Long 15
       pagos_a_cuanta_total = ''; --- Long 15
       saldo = ''; --- Long 15
       pagos_a_cuenta_creditos_debitos = ''; --- Long 15
       pagos_a_cuenta_percepciones_reten_aduaneras = ''; --- Long 15
       pagos_a_cuenta_resol_afip_3819_cancelaciones_efectivo_agen_turismo = ''; --- Long 15
       pagos_a_cuenta_bono_ley_27424 = '0'; --- Long 15
       pagos_a_cuenta_ley27541_art_35_inc_a = ''; --- Long 15
       pagos_a_cuenta_ley27541_art_35_inc_b = ''; --- Long 15
       pagos_a_cuenta_ley27541_art_35_inc_c = ''; --- Long 15
       pagos_a_cuenta_ley27541_art_35_inc_d = ''; --- Long 15
       pagos_a_cuenta_ley27541_art_35_inc_e = ''; --- Long 15
       pagos_a_cuenta_impuesto_creditos_debitos_fondos_propios_terceros = ''; --- Long 15
       pagos_a_cuenta_resolucion_afip_servicios_transporte_destino_fuera_pais = ''; --- Long 15




RETURN cant;
END;
$function$
