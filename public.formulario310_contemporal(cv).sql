CREATE OR REPLACE FUNCTION public.formulario310_contemporal(character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$DECLARE
  rparam RECORD;

  respuesta varchar;
BEGIN

     respuesta = '';
     EXECUTE sys_dar_filtros($1) INTO rparam;  

     CREATE TEMP TABLE temp_formulario310_contemporal AS (
    
         select 
nrodoc,
barra,
apellido, 
nombres, 
fechanac,
date(fmiffechaingreso) as fmiffechaingreso,

		 fmiflaboratorio->>'hba1c' AS hba1c,
        fmiflaboratorio->>'glucemia' AS glucemia,
        fmiflaboratorio->>'creatinina' AS creatinina,
        fmiflaboratorio->>'albuminuria' AS albuminuria,
        fmiflaboratorio->>'fechalaboratorio' AS fechalaboratorio,
        fmiflaboratorio->>'indicecreatinina' AS indicecreatinina,
fmifcomorbilidades->> 'acv' as acv,

		fmifcomorbilidades->> 'imc' as imc,
fmifcomorbilidades->> 'peso' as peso,
fmifcomorbilidades->> 'talla' as talla,
fmifcomorbilidades->> 'dislipemia' as dislipemia,
fmifcomorbilidades->> 'nefropatia' as nefropatia,
fmifcomorbilidades->> 'neuropatia' as neuropatia,
fmifcomorbilidades->> 'tabaquismo' as tabaquismo,
fmifcomorbilidades->> 'retinopatia' as retinopatia,
fmifcomorbilidades->> 'hipertension' as hipertension,
fmifcomorbilidades->> 'piediabetico' as piediabetico,

fmiftratamiento->> 'insulina' as insulina,
fmiftratamiento->> 'agonistas' as agonistas,
fmiftratamiento->> 'incretina' as incretina,
fmiftratamiento->> 'insulinaNPH' as insulinaNPH,
fmiftratamiento->> 'monitoreodia' as monitoreodia,
fmiftratamiento->> 'automonitoreo' as automonitoreo,
fmiftratamiento->> 'insulinaOTROS' as insulinaOTROS,
fmiftratamiento->> 'agonistasOTROS' as agonistasOTROS,
fmiftratamiento->> 'insulinaLISPRO' as insulinaLISPRO,
fmiftratamiento->> 'hipoglucemiante' as hipoglucemiante,
fmiftratamiento->> 'insulinaDETEMIR' as insulinaDETEMIR,
fmiftratamiento->> 'monitoreodia_ck' as monitoreodia_ck,
fmiftratamiento->> 'monitoreosemana' as monitoreosemana,
fmiftratamiento->> 'insulinaDEGLUDEC' as insulinaDEGLUDEC,
fmiftratamiento->> 'insulinaASPARTATO' as insulinaASPARTATO,
fmiftratamiento->> 'insulinaGLULISINA' as insulinaGLULISINA,
fmiftratamiento->> 'monitoreosemana_ck' as monitoreosemana_ck,
fmiftratamiento->> 'insulinaGLARGINA100' as insulinaGLARGINA100,
fmiftratamiento->> 'insulinaGLARGINA300' as insulinaGLARGINA300,
fmiftratamiento->> 'insulinaNPHunidades' as insulinaNPHunidades,
fmiftratamiento->> 'agonistasDULAGLUTIDE' as agonistasDULAGLUTIDE,
fmiftratamiento->> 'agonistasLIRAGLUTIDA' as agonistasLIRAGLUTIDA,
fmiftratamiento->> 'agonistasSEMAGLUTIDE' as agonistasSEMAGLUTIDE,
fmiftratamiento->> 'hipoglucemianteOTROS' as hipoglucemianteOTROS,
fmiftratamiento->> 'incretinaSITAGLIPTIN' as incretinaSITAGLIPTIN,
fmiftratamiento->> 'incretinaLINAGLIPTINA' as incretinaLINAGLIPTINA,
fmiftratamiento->> 'incretinaSITAGLIPTINA' as incretinaSITAGLIPTINA,
fmiftratamiento->> 'insulinaOTROSunidades' as insulinaOTROSunidades,
fmiftratamiento->> 'agonistasOTROSunidades' as agonistasOTROSunidades,
fmiftratamiento->> 'incretinaVILDAGLIPTINA' as incretinaVILDAGLIPTINA,
fmiftratamiento->> 'insulinaLISPROunidades' as insulinaLISPROunidades,
fmiftratamiento->> 'insulinaDETEMIRunidades' as insulinaDETEMIRunidades,
fmiftratamiento->> 'hipoglucemianteglimemetf' as hipoglucemianteglimemetf,
fmiftratamiento->> 'incretinalinagliptinmetf' as incretinalinagliptinmetf,
fmiftratamiento->> 'insulinaDEGLUDECunidades' as insulinaDEGLUDECunidades,
fmiftratamiento->> 'agonistasDULAGLUTIDEdosis' as agonistasDULAGLUTIDEdosis,
fmiftratamiento->> 'agonistasLIRAGLUTIDAdosis' as agonistasLIRAGLUTIDAdosis,
fmiftratamiento->> 'agonistasSEMAGLUTIDEdosis' as agonistasSEMAGLUTIDEdosis,
fmiftratamiento->> 'hipoglucemianteGLICLAZIDA' as hipoglucemianteGLICLAZIDA,
fmiftratamiento->> 'hipoglucemianteGLIMEPRIDA' as hipoglucemianteGLIMEPRIDA,
fmiftratamiento->> 'hipoglucemianteMETFORMINA' as hipoglucemianteMETFORMINA,
fmiftratamiento->> 'incretinaSITAGLIPTINdosis' as incretinaSITAGLIPTINdosis,
fmiftratamiento->> 'insulinaASPARTATOunidades' as insulinaASPARTATOunidades,
fmiftratamiento->> 'insulinaGLULISINAunidades' as insulinaGLULISINAunidades,
fmiftratamiento->> 'incretinaLINAGLIPTINAdosis' as incretinaLINAGLIPTINAdosis,
fmiftratamiento->> 'incretinaSITAGLIPTINAdosis' as incretinaSITAGLIPTINAdosis,
fmiftratamiento->> 'incretinaVILDAGLIPTINAMETF' as incretinaVILDAGLIPTINAMETF,
fmiftratamiento->> 'incretinaVILDAGLIPTINAdosis' as incretinaVILDAGLIPTINAdosis,
fmiftratamiento->> 'insulinaGLARGINA100unidades' as insulinaGLARGINA100unidades,
fmiftratamiento->> 'hipoglucemianteGLIBENCLAMIDA' as hipoglucemianteGLIBENCLAMIDA,
fmiftratamiento->> 'insulinaGLARGINA300unidades' as insulinaGLARGINA300unidades,
fmiftratamiento->> 'hipoglucemianteOTROSunidades' as hipoglucemianteOTROSunidades,
fmiftratamiento->> 'hipoglucemianteDAPAGLIFLOZINA' as hipoglucemianteDAPAGLIFLOZINA,
fmiftratamiento->> 'hipoglucemianteEMPAGLIFLOZINA' as hipoglucemianteEMPAGLIFLOZINA,
fmiftratamiento->> 'hipoglucemianteGLIPIZIDAdosis' as hipoglucemianteGLIPIZIDAdosis,
fmiftratamiento->> 'hipoglucemianteglimemetfdosis' as hipoglucemianteglimemetfdosis,
fmiftratamiento->> 'incretinalinagliptinmetfdosis' as incretinalinagliptinmetfdosis,
fmiftratamiento->> 'hipoglucemianteGLICLAZIDAdosis'as hipoglucemianteGLICLAZIDAdosis,
fmiftratamiento->> 'hipoglucemianteGLIMEPRIDAdosis'as hipoglucemianteGLIMEPRIDAdosis,
fmiftratamiento->> 'hipoglucemianteMETFORMINAdosis'as hipoglucemianteMETFORMINAdosis,
fmiftratamiento->> 'incretinaVILDAGLIPTINAMETFdosis'as incretinaVILDAGLIPTINAMETFdosis,
fmiftratamiento->> 'hipoglucemianteGLIBENCLAMIDAdosis'as hipoglucemianteGLIBENCLAMIDAdosis,
fmiftratamiento->> 'hipoglucemianteDAPAGLIFLOZINAdosis'as hipoglucemianteDAPAGLIFLOZINAdosis,
fmiftratamiento->> 'hipoglucemianteEMPAGLIFLOZINAdosis'as hipoglucemianteEMPAGLIFLOZINAdosis,
fmifdiagnosticoj->> 'diabetesLADA' as diabetesLADA,
fmifdiagnosticoj->> 'diabetesMODY' as diabetesMODY,
fmifdiagnosticoj->> 'diabetesTipo1' as diabetesTipo1,
fmifdiagnosticoj->> 'diabetesTipo2' as diabetesTipo2,
fmifdiagnosticoj->> 'fechaDiagnostico' as fechaDiagnostico,
fmifdiagnosticoj->> 'diabetesGestacional' as diabetesGestacional,
fmifdiagnosticoj->> 'diabetesInsulinoRequiriente' as diabetesInsulinoRequiriente,
		 
'1-nrodoc#nrodoc@2-barra#barra@3-apellido#apellido@4-nombres#nombres@5-fechanac#fechanac@6-fmiffechaingreso#fmiffechaingreso@7-hba1c#hba1c@8-glucemia#glucemia@9-creatinina#creatinina@10-albuminuria#albuminuria@11-fechalaboratorio#fechalaboratorio@12-indicecreatinina#indicecreatinina@13-acv#acv@14-imc#imc@15-peso#peso@16-talla#talla@17-dislipemia#dislipemia@18-nefropatia#nefropatia@19-neuropatia#neuropatia@20-tabaquismo#tabaquismo@21-retinopatia#retinopatia@22-hipertension#hipertension@23-piediabetico#piediabetico@24-insulina#insulina@25-agonistas#agonistas@26-incretina#incretina@27-insulinaNPH#insulinaNPH@28-monitoreodia#monitoreodia@29-automonitoreo#automonitoreo@30-insulinaOTROS#insulinaOTROS@31-agonistasOTROS#agonistasOTROS@32-insulinaLISPRO#insulinaLISPRO@33-hipoglucemiante#hipoglucemiante@34-insulinaDETEMIR#insulinaDETEMIR@35-monitoreodia_ck#monitoreodia_ck@36-monitoreosemana#monitoreosemana@37-insulinaDEGLUDEC#insulinaDEGLUDEC@38-insulinaASPARTATO#insulinaASPARTATO@39-insulinaGLULISINA#insulinaGLULISINA@40-monitoreosemana_ck#monitoreosemana_ck@41-insulinaGLARGINA100#insulinaGLARGINA100@42-insulinaGLARGINA300#insulinaGLARGINA300@43-insulinaNPHunidades#insulinaNPHunidades@44-agonistasDULAGLUTIDE#agonistasDULAGLUTIDE@45-agonistasLIRAGLUTIDA#agonistasLIRAGLUTIDA@46-agonistasSEMAGLUTIDE#agonistasSEMAGLUTIDE@47-hipoglucemianteOTROS#hipoglucemianteOTROS@48-incretinaSITAGLIPTIN#incretinaSITAGLIPTIN@49-incretinaLINAGLIPTINA#incretinaLINAGLIPTINA@50-incretinaSITAGLIPTINA#incretinaSITAGLIPTINA@51-insulinaOTROSunidades#insulinaOTROSunidades@52-agonistasOTROSunidades#agonistasOTROSunidades@53-incretinaVILDAGLIPTINA#incretinaVILDAGLIPTINA@54-insulinaLISPROunidades#insulinaLISPROunidades@55-insulinaDETEMIRunidades#insulinaDETEMIRunidades@56-hipoglucemianteglimemetf#hipoglucemianteglimemetf@57-incretinalinagliptinmetf#incretinalinagliptinmetf@58-insulinaDEGLUDECunidades#insulinaDEGLUDECunidades@59-agonistasDULAGLUTIDEdosis#agonistasDULAGLUTIDEdosis@60-agonistasLIRAGLUTIDAdosis#agonistasLIRAGLUTIDAdosis@61-agonistasSEMAGLUTIDEdosis#agonistasSEMAGLUTIDEdosis@62-hipoglucemianteGLICLAZIDA#hipoglucemianteGLICLAZIDA@63-hipoglucemianteGLIMEPRIDA#hipoglucemianteGLIMEPRIDA@64-hipoglucemianteMETFORMINA#hipoglucemianteMETFORMINA@65-incretinaSITAGLIPTINdosis#incretinaSITAGLIPTINdosis@66-insulinaASPARTATOunidades#insulinaASPARTATOunidades@67-insulinaGLULISINAunidades#insulinaGLULISINAunidades@68-incretinaLINAGLIPTINAdosis#incretinaLINAGLIPTINAdosis@69-incretinaSITAGLIPTINAdosis#incretinaSITAGLIPTINAdosis@70-incretinaVILDAGLIPTINAMETF#incretinaVILDAGLIPTINAMETF@71-incretinaVILDAGLIPTINAdosis#incretinaVILDAGLIPTINAdosis@72-insulinaGLARGINA100unidades#insulinaGLARGINA100unidades@73-hipoglucemianteGLIBENCLAMIDA#hipoglucemianteGLIBENCLAMIDA@74-insulinaGLARGINA300unidades#insulinaGLARGINA300unidades@75-hipoglucemianteOTROSunidades#hipoglucemianteOTROSunidades@76-hipoglucemianteDAPAGLIFLOZINA#hipoglucemianteDAPAGLIFLOZINA@77-hipoglucemianteEMPAGLIFLOZINA#hipoglucemianteEMPAGLIFLOZINA@78-hipoglucemianteGLIPIZIDAdosis#hipoglucemianteGLIPIZIDAdosis@79-hipoglucemianteglimemetfdosis#hipoglucemianteglimemetfdosis@80-incretinalinagliptinmetfdosis#incretinalinagliptinmetfdosis@81-hipoglucemianteGLICLAZIDAdosis#hipoglucemianteGLICLAZIDAdosis@82-hipoglucemianteGLIMEPRIDAdosis#hipoglucemianteGLIMEPRIDAdosis@83-hipoglucemianteMETFORMINAdosis#hipoglucemianteMETFORMINAdosis@84-incretinaVILDAGLIPTINAMETFdosis#incretinaVILDAGLIPTINAMETFdosis@85-hipoglucemianteGLIBENCLAMIDAdosis#hipoglucemianteGLIBENCLAMIDAdosis@86-hipoglucemianteDAPAGLIFLOZINAdosis#hipoglucemianteDAPAGLIFLOZINAdosis@87-hipoglucemianteEMPAGLIFLOZINAdosis#hipoglucemianteEMPAGLIFLOZINAdosis@88-diabetesLADA#diabetesLADA@89-diabetesMODY#diabetesMODY@90-diabetesTipo1#diabetesTipo1@91-diabetesTipo2#diabetesTipo2@92-fechaDiagnostico#fechaDiagnostico@93-diabetesGestacional#diabetesGestacional@94-diabetesInsulinoRequiriente#diabetesInsulinoRequiriente'::text as mapeocampocolumna

from fichamedicainfoformulario
left join persona using (nrodoc)

where fmiffechaingreso >= '2022-10-13'

order by fmiffechaingreso asc 

--LIMIT 1

       );
 
   
--por ahora ponemos esto. 
     respuesta = 'todook';
     
    
    
return respuesta;
END;$function$
