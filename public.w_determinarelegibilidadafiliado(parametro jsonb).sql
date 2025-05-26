CREATE OR REPLACE FUNCTION public.w_determinarelegibilidadafiliado(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"NroAfiliado":"28272137","Barra":30,"NroDocumento":null,"TipoDocumento":null,"Track":null}
*/
DECLARE
--VARIABLES 
   vmontoctacte DOUBLE PRECISION;
--RECORD
      respuestajson jsonb;
      jsontitular  jsonb;
      vrespmontodisp character varying;
      rpersona RECORD;
      rafiliado  RECORD;
      rformapagouw RECORD;
begin
       vmontoctacte = 0;
       IF nullvalue(parametro->>'NroDocumento') AND nullvalue(parametro->>'TipoDocumento') 
		AND nullvalue(parametro->>'NroAfiliado') AND nullvalue(parametro->>'Barra')
		AND nullvalue(parametro->>'Track')  THEN 
			RAISE EXCEPTION 'R-001, Al Menos uno de los parametros deben estar completos.  %',parametro;
		END IF;
		IF not nullvalue(parametro->>'NroDocumento') AND not nullvalue(parametro->>'TipoDocumento') THEN 
			SELECT INTO rpersona nrodoc as nroafiliado
						,barra
						,nrodoc as nrodocumento
						,descrip as tipodocumento
						,nombres
						,apellido
						,sexo
						,fechanac as fechanacimiento
										,fechafinos
										,CASE WHEN fechafinos > current_date THEN 'Activo' ELSE 'Pasivo' END as estado  
						FROM persona 
										NATURAL JOIN tiposdoc
						WHERE nrodoc = parametro->>'NroDocumento' 
								AND descrip = parametro->>'TipoDocumento'
								AND fechafinos >= current_date;
			IF FOUND THEN 
							respuestajson = row_to_json(rpersona);                   	
			ELSE 
				RAISE EXCEPTION 'R-001, El afiliado no esta activo o no existe.'; --(NroDoc,Tipodoc,%)',parametro; -- sl 11/10/23 - Comento para que no se vea los parametros en el error desde la APP
			END IF;
        END IF;     
	IF not nullvalue(parametro->>'NroAfiliado') AND not nullvalue(parametro->>'Barra') THEN 
		SELECT INTO rpersona nrodoc as nroafiliado
				     ,barra
				     ,nrodoc as nrodocumento
				     ,descrip as tipodocumento
				     ,nombres
				     ,apellido
				     ,sexo
				     ,fechanac as fechanacimiento 
                                     ,fechafinos
                                     ,CASE WHEN fechafinos > current_date THEN 'Activo' ELSE 'Pasivo' END as estado
				     FROM persona 
                                     NATURAL JOIN tiposdoc
				     WHERE nrodoc = TRIM(parametro->>'NroAfiliado')
							AND barra = parametro->>'Barra'
							AND fechafinos >= current_date;
		IF FOUND THEN 
                    respuestajson = row_to_json(rpersona); 
		ELSE 
		    RAISE EXCEPTION 'R-002, El afiliado no esta activo o no existe.'; --(NroAfiliado,Barra,%)',parametro; -- sl 11/10/23 - Comento para que no se vea los parametros en el error desde la APP
		END IF;
       END IF;     
       IF not nullvalue(parametro->>'Track') THEN 
		SELECT INTO rpersona nrodoc as nroafiliado
				     ,barra
				     ,nrodoc as nrodocumento
				     ,descrip as tipodocumento
				     ,nombres
				     ,apellido
				     ,sexo
				     ,fechanac as fechanacimiento 
				     FROM persona 
                                     NATURAL JOIN tiposdoc   
				     WHERE  parametro->>'Track' ilike concat('%',nrodoc,'_')
					AND fechafinos >= current_date;
		IF FOUND THEN 
			respuestajson = row_to_json(rpersona);
		ELSE 
			RAISE EXCEPTION 'R-003, El afiliado no esta activo o no existe.';--(Track,%)',parametro;
		END IF;
       END IF;     	

 --KR 14-04-20 saco la forma de pago de w_usuariowebprestador    IF (parametro->>'uwnombre' = 'usucbn' OR parametro->>'uwnombre' = 'usucbrn') THEN
      SELECT INTO rformapagouw * FROM public.w_usuariowebprestador NATURAL JOIN w_usuarioweb WHERE uwnombre = parametro->>'uwnombre';
      IF FOUND AND rformapagouw.uwpformapagotipodefecto = 3 THEN -- La forma de pago es cta cte
 

           PERFORM afiliaciones_datosgrupofamiliar(CONCAT('{nrodoc=',rpersona.nrodocumento,'}'));
           SELECT INTO rafiliado * FROM afiliado;
           IF FOUND THEN 
             IF rafiliado.barra<100 THEN 
              --KR 24-10-19 Verifico que el afiliado tenga disponible en la cta cte un monto para ser consumido si el prestador es de usucbrn O usucbn. Si el afiliado no tiene disponible NO puede usar suap
                --SELECT INTO vmontoctacte * FROM montodisponible(CONCAT('{nrodoc=', parametro->>'NroAfiliado' ,'}'));

                --SL 12/05/25 - Modifico el monto para utilizar el nuevo que contempla toda la ctacte
                SELECT INTO jsontitular * FROM dartitular(CONCAT('{"nrodoc":"', parametro->>'NroAfiliado','"}')::JSONB);
                SELECT INTO vrespmontodisp * FROM calcularmontodispcuentacorriente(CONCAT('{nrodoc=', jsontitular->>'nrodoc' , ', tipodoc=', jsontitular->>'tipodoc','}'));
                --Separo el texto por "," ya que el sp devuelve "X, false" en forma de texto y luego trasnformo en double
                vmontoctacte = split_part(vrespmontodisp, ',', 1)::DOUBLE PRECISION;

             	-- SL 21/11/23 - Modifico condicion para la emision de ordenes a los jubilados desde la APP
               IF vmontoctacte<=0 THEN --EL AFILIADO no PUEDE USAR Validacion online
                     --RAISE EXCEPTION 'R-001, El afiliado no tiene habilitado el uso de SUAP.(Track,%)',parametro;
                     IF (parametro->>'uwnombre' = 'ususm' AND (rafiliado.barra = 35 OR rafiliado.barra = 36))THEN
                           ---- S/A solo tienen permiso los jubilados a consumir por la app
                     ELSE
                            RAISE EXCEPTION 'R-007, El afiliado no cumple los requisitos para validar en linea. Inicio en la obrasocial: %', to_char(rafiliado.fechainios, 'DD/MM/YYYY');
                     END IF;
               END IF;

	      ELSE  
                   --IF (rafiliado.barra=149 OR rafiliado.barra=131) THEN 
                   --BelenA 26/03/25 ahora los 149 pueden emitir ordenes desde la app
                   IF (rafiliado.barra=131) THEN 
                        RAISE EXCEPTION 'R-005, El afiliado no cumple los requisitos para validar en linea.';--(Track,%)',parametro;
              END IF; 
             END IF;

           END IF;
      END IF;
      
     --Buesco los planes de cobertura
    select into respuestajson row_to_json(t)
from (
select nrodoc as nroafiliado
				     ,barra
				     ,nrodoc as nrodocumento
				     ,descrip as tipodocumento
				     ,nombres
				     ,apellido
				     ,sexo
                                     ,tipodoc as idtipodocumento
				     ,fechanac as fechanacimiento
                                     ,TO_CHAR(fechafinos, 'dd/mm/yyyy') as fechafinos
                                     ,CASE WHEN fechafinos > current_date THEN 'Activo' ELSE 'Pasivo' END as estado 
                                     ,CASE WHEN (barra > 29 AND barra < 100) THEN 'Titular'
                                       WHEN (barra < 30 AND barra >= 1) THEN 'Beneficiario'  
                                       WHEN (barra >= 100 AND barra < 130) THEN 'Beneficiario Reciprocidad'
                                      ELSE 'Titular Reciprocidad' END as tipoafiliado 
				      ,(
select  array_to_json(array_agg(row_to_json(t)))
    from ( 
	select idplancoberturas,nombreimprimir 
        from plancobertura 
        natural join plancobpersona 
         where nrodoc = respuestajson->>'nrodocumento' 
          and (nullvalue(pcpfechafin) OR pcpfechafin > current_date)
        ) as t
 ) as  planesafiliado
FROM  persona NATURAL JOIN tiposdoc 
WHERE nrodoc  = respuestajson->>'nrodocumento' 
 ) as t;

      return respuestajson;

end;$function$
