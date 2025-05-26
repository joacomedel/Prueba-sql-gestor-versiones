CREATE OR REPLACE FUNCTION public.turismo_info_generar_minuta(pfiltros character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$/*Esta funcion se usa para calcular los valores a pagar como Anticipo/saldo de las minutas de turismo
idturismoadmin=rfiltros.idturismoadmin
SELECT turismo_info_generar_minuta('{idturismoadmin=41, accion =turismo_dar_valores}');
SELECT * FROM turismo_para_minuta


*/
DECLARE
        rfiltros RECORD;
BEGIN

--vidusuario = sys_dar_usuarioactual();

EXECUTE sys_dar_filtros(pfiltros) INTO rfiltros;

	IF rfiltros.accion = 'turismo_dar_valores' THEN
		CREATE TEMP TABLE turismo_para_minuta AS (
			SELECT nrocuentac,desccuenta,  idprestamo, idcentroprestamo ,idconsumoturismo,idcentroconsumoturismo, idturismoadmin,ctfehcingreso, 		 ctfechasalida,(imptotaldelconsumo)as imptotaldelconsumo,tadescripcion,  CASE WHEN ( nullvalue(importepagadounidad)) then 0 ELSE importepagadounidad END  as importepagadounidad , CASE WHEN ( nullvalue(importepagadounidad)) then (imptotaldelconsumo) ELSE ((imptotaldelconsumo ) -  importepagadounidad)  END  as saldoconunidad , CASE WHEN (ctfechasalida >now() ) THEN             ceiling((imptotaldelconsumo) * 0.4) ELSE       CASE WHEN nullvalue (importepagadounidad) THEN (imptotaldelconsumo) ELSE ((imptotaldelconsumo )- importepagadounidad )END END as saldoapagarconunidad ,denominacion  , CASE WHEN ( nullvalue(importepagadounidad)) then 'Anticipo' ELSE 'Saldo' END  as enconcepto

		FROM consumoturismo 
		NATURAL JOIN  consumoturismoestado 
		NATURAL JOIN (   SELECT idconsumoturismo, idcentroconsumoturismo , idturismoadmin,tadescripcion         , 		                  
                     SUM( CASE WHEN (tuvporpersona) THEN ((tuvimportesosunc * ctvcantdias *cantperso)+ (tuvimporteinvitadososunc * ctvcantdias *cantperinvitado)) 		                       ELSE (tuvimportesosunc*ctvcantdias) END
 		              )as imptotaldelconsumo		 		                  
                  FROM consumoturismovalores
                  NATURAL JOIN turismounidadvalor 	
                  NATURAL JOIN turismounidad 
                  NATURAL JOIN turismoadmin 
		          LEFT JOIN (  SELECT  idconsumoturismo ,idcentroconsumoturismo,SUM(cantperinvitado)as cantperinvitado,SUM(cantper)as cantperso
		                       FROM (SELECT idconsumoturismo ,idcentroconsumoturismo, count(*) as cantperinvitado,0 as cantper 	
                                     FROM grupoacompaniante
                                     WHERE invitado
		                             GROUP by idconsumoturismo ,idcentroconsumoturismo
                                     UNION
                                     SELECT idconsumoturismo ,idcentroconsumoturismo, 0 as cantperinvitado, count(*) as cantper
 		                             FROM grupoacompaniante
		                             WHERE not invitado
	                                 GROUP by idconsumoturismo ,idcentroconsumoturismo
		                       ) as CP 		                                   
                               GROUP by idconsumoturismo ,idcentroconsumoturismo
 		            )as GA USING(idconsumoturismo ,idcentroconsumoturismo)
 		            WHERE  not ctvborrado 
					        and idturismoadmin=rfiltros.idturismoadmin
		            group by idconsumoturismo ,idcentroconsumoturismo,idturismoadmin, tadescripcion 		                  
		) as t 		 
		NATURAL JOIN prestamo 		 
		JOIN cliente ON  (tipodoc = barra and  nrocliente = nrodoc)
		LEFT JOIN (
     		 SELECT idcentroconsumoturismo,idconsumoturismo, (SUM(ctopimportepagado) + SUM(ctopimportedebitado)) as importepagadounidad 
      		FROM consumoturismoordenpago 
      		natural join cambioestadoordenpago
      		WHERE    idtipoestadoordenpago <> 4  AND nullvalue(ceopfechafin)
      		group by idcentroconsumoturismo,idconsumoturismo 
 		) as TOP  using (idcentroconsumoturismo,idconsumoturismo)
		natural join cuentascontables 		 
		WHERE 	idconsumoturismoestadotipos<>3 and idconsumoturismoestadotipos<>5  and nullvalue(ctefechafin)
		order by ctfechasalida asc 
		);
	
	END IF;
 
RETURN 'true';
END;
$function$
