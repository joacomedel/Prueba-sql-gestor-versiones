CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_auditoria_guardarinfo(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*
*/
DECLARE

      respuestajson jsonb;
	  usuariojson jsonb;
      rorden RECORD;
      rexiste  RECORD;
      rprestador RECORD;
      rconsumo  RECORD;
      vnroorden bigint;
	 vcentro bigint;
	 vttl timestamp;
	 vidformulario bigint;
	 vtexto VARCHAR;
	 vtextodesc VARCHAR;
begin
--row_to_json(row(1,'foo'))
	   SELECT INTO rexiste * FROM w_usuariowebtokensession WHERE uwtkstoken = trim(parametro->>'tokensession');
	    IF FOUND THEN
			vnroorden = (rexiste.uwtkscodigo)::bigint / 100;
	   		vcentro = (rexiste.uwtkscodigo)::bigint  % 100;
	   		SELECT INTO usuariojson sys_dar_usuario_web(parametro);
	   		
	   		SELECT INTO rconsumo * FROM consumo where nroorden = vnroorden AND centro = vcentro;
	   		SELECT INTO rprestador * FROM prestador WHERE pcuit = trim(parametro->>'prespcuit');
			
                        UPDATE  fichamedicainfoformulario SET fmiffechafin = now() WHERE nullvalue(fmiffechafin) AND fmifnroorden = vnroorden                                                        AND	fmifcentro = vcentro;
			INSERT INTO fichamedicainfoformulario(fmiffechaingreso,fmimfidprestador,nrodoc,tipodoc,fmifusuario,fmifnroorden,fmifcentro,fmifcorreoafiliado,fmiftelefonoafiliado,fmifprestadorcargado,fmifformulario) 
			VALUES(now(),rprestador.idprestador,rconsumo.nrodoc,rconsumo.tipodoc,(usuariojson->>'idusuario')::integer,vnroorden,vcentro,parametro->>'email',parametro->>'telefonos',parametro->>'prespemail',parametro) ;
			vidformulario = currval('fichamedicainfoformulario_idfichamedicainfoformulario_seq'::regclass);
			vcentro = centro();
			vtexto = concat('{ "prespdescripcion",',parametro->>'prespdescripcion',
							', "prespcuit" ,',CASE WHEN nullvalue(parametro->>'prespcuit') OR parametro->>'prespcuit' = '' THEN '99-12345678-0 ' ELSE parametro->>'prespcuit' END ,
							', "presmatricula", "',parametro->>'presmatricula',
							'","presmalcance","',parametro->>'presmalcance',
							'","presmespecialidad","',parametro->>'presmespecialidad',
							'","prespemail","',parametro->>'prespemail',
							'","presptelefonomovil","',parametro->>'presptelefonomovil',
							'","prespcontacto","',parametro->>'prespcontacto',
							'"}');
			UPDATE fichamedicainfoformulario SET fmifprestador = json_object(vtexto::text[]) WHERE idfichamedicainfoformulario = vidformulario AND idcentrofichamedicainfoformulario = vcentro;
			
			vtexto = concat('{"fechalaboratorio","',parametro->>'fechalaboratorio',
							'", "hba1c" ,"',parametro->>'hba1c',
							'", "glucemia", "',parametro->>'glucemia',
							'","creatinina","',parametro->>'creatinina',
							'","indicecreatinina","',parametro->>'indicecreatinina',
							'","albuminuria","',parametro->>'albuminuria',
							'"}');
			
			UPDATE fichamedicainfoformulario SET fmiflaboratorio = json_object(vtexto::text[]) WHERE idfichamedicainfoformulario = vidformulario AND idcentrofichamedicainfoformulario = vcentro;
			vtexto = concat('{peso,"',parametro->>'peso',
							'", "talla" ,"',parametro->>'talla',
							'", "imc", "',parametro->>'imc',
							'","retinopatia","',parametro->>'retinopatia',
							'","neuropatia","',parametro->>'neuropatia',
							'","acv","',parametro->>'acv',
							'","nefropatia","',parametro->>'nefropatia',
							'","piediabetico","',parametro->>'piediabetico',
							'","dislipemia","',parametro->>'dislipemia',
							'","tabaquismo","',parametro->>'tabaquismo',
							'","hipertension","',parametro->>'hipertension',
							'"}');
							
			UPDATE fichamedicainfoformulario SET fmifcomorbilidades = json_object(vtexto::text[]) WHERE idfichamedicainfoformulario = vidformulario AND idcentrofichamedicainfoformulario = vcentro;
			vtexto = concat('{"fechaDiagnostico","',parametro->>'fechaDiagnostico',
							'", "diabetesTipo1" ,"',parametro->>'diabetesTipo1',
							'", "diabetesTipo2", "',parametro->>'diabetesTipo2',
							'","diabetesGestacional","',parametro->>'diabetesGestacional',
							'","diabetesLADA","',parametro->>'diabetesLADA',
							'","diabetesMODY","',parametro->>'diabetesMODY',
							'","diabetesInsulinoRequiriente","',parametro->>'diabetesInsulinoRequiriente',
							'"}');
			vtextodesc =  concat('{Fecha de Diagnostico:,',parametro->>'fechaDiagnostico',
							', " Tiene Diabetes de tipo 1: " ,',parametro->>'diabetesTipo1',
							', " Tiene Diabetes de tipo 2: ", "',parametro->>'diabetesTipo2',
							'"," Tiene Diabetes GESTACIONAL: ","',parametro->>'diabetesGestacional',
							'"," Tiene Diabetes LADA: ","',parametro->>'diabetesLADA',
							'"," Tiene Diabetes MODY: ","',parametro->>'diabetesMODY',
							'"," Tiene hipertension","',parametro->>'hipertension',
							'"," Es INSULINO REQUIRENTE","',parametro->>'diabetesInsulinoRequiriente',
							'"}');
							
			UPDATE fichamedicainfoformulario SET fmifdiagnosticoj = json_object(vtexto::text[]) , fmifdiagnostico = vtextodesc , fmifdiaobservacion = '' WHERE idfichamedicainfoformulario = vidformulario 	AND idcentrofichamedicainfoformulario = vcentro;
			
			vtexto = concat('{"insulina","',parametro->>'insulina',
                                         '", "insulinaASPARTATO" ,"',parametro->>'insulinaASPARTATO',
					'", "insulinaASPARTATOunidades" ,"',parametro->>'insulinaASPARTATOunidades',
					'", "insulinaDEGLUDEC" ,"',parametro->>'insulinaDEGLUDEC',
					'", "insulinaDEGLUDECunidades" ,"',parametro->>'insulinaDEGLUDECunidades',
					'", "insulinaLISPRO" ,"',parametro->>'insulinaLISPRO',
					'", "insulinaLISPROunidades" ,"',parametro->>'insulinaLISPROunidades',
					'", "insulinaNPH" ,"',parametro->>'insulinaNPH',
					'", "insulinaNPHunidades" ,"',parametro->>'insulinaNPHunidades',
					'", "insulinaGLULISINA" ,"',parametro->>'insulinaGLULISINA',
					'", "insulinaGLULISINAunidades" ,"',parametro->>'insulinaGLULISINAunidades',
					'", "insulinaDETEMIR" ,"',parametro->>'insulinaDETEMIR',
					'", "insulinaDETEMIRunidades" ,"',parametro->>'insulinaDETEMIRunidades',
					'", "insulinaGLARGINA100" ,"',parametro->>'insulinaGLARGINA100',
					'"');
							
			vtexto = concat(vtexto,', "insulinaGLARGINA100unidades","',parametro->>'insulinaGLARGINA100unidades',
                                         '", "insulinaGLARGINA300" ,"',parametro->>'insulinaGLARGINA300',
					'", "insulinaGLARGINA300unidades" ,"',parametro->>'insulinaGLARGINA300unidades',
					'", "insulinaOTROS" ,"',parametro->>'insulinaOTROS',
					'", "insulinaOTROSunidades" ,"',parametro->>'insulinaOTROSunidades',
					'"');
			vtexto = concat(vtexto,', "hipoglucemiante","',parametro->>'hipoglucemiante',
                                         '", "hipoglucemianteMETFORMINA" ,"',parametro->>'hipoglucemianteMETFORMINA',
					'", "hipoglucemianteMETFORMINAdosis" ,"',parametro->>'hipoglucemianteMETFORMINAdosis',
					'", "hipoglucemianteGLIPIZIDAdosis" ,"',parametro->>'hipoglucemianteGLIPIZIDAdosis',
					'", "hipoglucemianteEMPAGLIFLOZINA" ,"',parametro->>'hipoglucemianteEMPAGLIFLOZINA',
					'", "hipoglucemianteEMPAGLIFLOZINAdosis" ,"',parametro->>'hipoglucemianteEMPAGLIFLOZINAdosis',
					'", "hipoglucemianteGLIBENCLAMIDA" ,"',parametro->>'hipoglucemianteGLIBENCLAMIDA',
					'", "hipoglucemianteGLIBENCLAMIDAdosis" ,"',parametro->>'hipoglucemianteGLIBENCLAMIDAdosis',
					'", "hipoglucemianteGLIMEPRIDA" ,"',parametro->>'hipoglucemianteGLIMEPRIDA',
					'", "hipoglucemianteGLIMEPRIDAdosis" ,"',parametro->>'hipoglucemianteGLIMEPRIDAdosis',
					'", "hipoglucemianteDAPAGLIFLOZINA" ,"',parametro->>'hipoglucemianteDAPAGLIFLOZINA',
					'", "hipoglucemianteDAPAGLIFLOZINAdosis" ,"',parametro->>'hipoglucemianteDAPAGLIFLOZINAdosis',
					'", "hipoglucemianteGLICLAZIDA" ,"',parametro->>'hipoglucemianteGLICLAZIDA',
					'", "hipoglucemianteGLICLAZIDAdosis" ,"',parametro->>'hipoglucemianteGLICLAZIDAdosis',
					'", "hipoglucemianteglimemetf" ,"',parametro->>'hipoglucemianteglimemetf',
					'", "hipoglucemianteglimemetfdosis" ,"',parametro->>'hipoglucemianteglimemetfdosis',
					'", "hipoglucemianteOTROS" ,"',parametro->>'hipoglucemianteOTROS',
					'", "hipoglucemianteOTROSunidades" ,"',parametro->>'hipoglucemianteOTROSunidades',
					'"');
			vtexto = concat(vtexto,', "incretina","',parametro->>'incretina',
                                         '", "incretinaSITAGLIPTINA" ,"',parametro->>'incretinaSITAGLIPTINA',
					'", "incretinaSITAGLIPTINAdosis" ,"',parametro->>'incretinaSITAGLIPTINAdosis',
					'", "incretinaSITAGLIPTIN" ,"',parametro->>'incretinaSITAGLIPTIN',
					'", "incretinaSITAGLIPTINdosis" ,"',parametro->>'incretinaSITAGLIPTINdosis',
					'", "incretinaVILDAGLIPTINA" ,"',parametro->>'incretinaVILDAGLIPTINA',
					'", "incretinaVILDAGLIPTINAdosis" ,"',parametro->>'incretinaVILDAGLIPTINAdosis',
					'", "incretinaVILDAGLIPTINAMETF" ,"',parametro->>'incretinaVILDAGLIPTINAMETF',
					'", "incretinaVILDAGLIPTINAMETFdosis" ,"',parametro->>'incretinaVILDAGLIPTINAMETFdosis',
					'", "incretinaLINAGLIPTINA" ,"',parametro->>'incretinaLINAGLIPTINA',
					'", "incretinaLINAGLIPTINAdosis" ,"',parametro->>'incretinaLINAGLIPTINAdosis',
					'", "incretinalinagliptinmetf" ,"',parametro->>'incretinalinagliptinmetf',
					'", "incretinalinagliptinmetfdosis" ,"',parametro->>'incretinalinagliptinmetfdosis',
					'"');
					
					vtexto = concat(vtexto,', "agonistas","',parametro->>'agonistas',
                                         '", "agonistasSEMAGLUTIDE" ,"',parametro->>'agonistasSEMAGLUTIDE',
					'", "agonistasSEMAGLUTIDEdosis" ,"',parametro->>'agonistasSEMAGLUTIDEdosis',
					'", "agonistasDULAGLUTIDE" ,"',parametro->>'agonistasDULAGLUTIDE',
					'", "agonistasDULAGLUTIDEdosis" ,"',parametro->>'agonistasDULAGLUTIDEdosis',
					'", "agonistasLIRAGLUTIDA" ,"',parametro->>'agonistasLIRAGLUTIDA',
					'", "agonistasLIRAGLUTIDAdosis" ,"',parametro->>'agonistasLIRAGLUTIDAdosis',
					'", "agonistasOTROS" ,"',parametro->>'agonistasOTROS',
					'", "agonistasOTROSunidades" ,"',parametro->>'agonistasOTROSunidades',
					'"');
					vtexto = concat(vtexto,', "automonitoreo","',parametro->>'automonitoreo',
                                         '", "monitoreosemana_ck" ,"',parametro->>'monitoreosemana_ck',
                                         '", "monitoreodia_ck" ,"',parametro->>'monitoreodia_ck',
                                        '", "monitoreodia" ,"',parametro->>'monitoreodia',
					'", "monitoreosemana" ,"',parametro->>'monitoreosemana',
					'"}');
					
			UPDATE fichamedicainfoformulario SET fmiftratamiento = json_object(vtexto::text[]) WHERE idfichamedicainfoformulario = vidformulario 	AND idcentrofichamedicainfoformulario = vcentro;
	
           --Terminar esto para que guarde el archivo... hay que usar el Web Services que gurda un archivo		
		   --Campo discriminante 1 - Laboratorios 2 - Prestador 3 - Formulario
			INSERT INTO fichamedicainfoformularioarchivo ( fmifausuario, idfichamedicainfoformulario, idcentrofichamedicainfoformulario, fmifadiscriminante,idarchivo, idcentroarchivo)
														  VALUES((usuariojson->>'idusuario')::integer,vidformulario,vcentro,1,null,null);
			INSERT INTO fichamedicainfoformularioarchivo ( fmifausuario, idfichamedicainfoformulario, idcentrofichamedicainfoformulario, fmifadiscriminante,idarchivo, idcentroarchivo)
														  VALUES((usuariojson->>'idusuario')::integer,vidformulario,vcentro,2,null,null);
			INSERT INTO fichamedicainfoformularioarchivo ( fmifausuario, idfichamedicainfoformulario, idcentrofichamedicainfoformulario, fmifadiscriminante,idarchivo, idcentroarchivo)
														  VALUES((usuariojson->>'idusuario')::integer,vidformulario,vcentro,3,null,null);
			
			
		END IF;
		
		vtexto = concat('{"idfichamedicainfoformulario","',vidformulario,
							'", "idcentrofichamedicainfoformulario" ,"',vcentro,
							'"}');
		respuestajson = json_object(vtexto::text[]);
       return respuestajson;

end;
$function$
