CREATE OR REPLACE FUNCTION public.sys_modifcar_coberturas_medicamento()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE
  	cursormono CURSOR FOR SELECT DISTINCT idmonodroga,monnombre,drogas_mas_asociaciones,droga,nombre_comercial,multiplicador,mafechaproceso,round((manuevomultiplicador/100.0)::numeric,2) as nuevacobertura 
					FROM (
						select idmonodroga,monnombre,drogas_mas_asociaciones,droga,nombre_comercial,manuevomultiplicador,mafechaproceso
							from medicam_anticonceptivos_borrar
							JOIN medicamento ON codalfabeta = mnroregistro
							JOIN manextra USING (mnroregistro)
							JOIN monodroga USING (idmonodroga)
                                                         WHERE  nullvalue(mafechaproceso)
							) as paracambiar
							LEFT JOIN (SELECT * FROM plancoberturafarmacia WHERE nullvalue(fechafinvigencia)) as plancoberturafarmacia USING(idmonodroga)
							WHERE multiplicador <> round((manuevomultiplicador/100.0)::numeric,2)
							    
							
							;

	rmono RECORD;
        rverifica RECORD;
	

BEGIN
--MaLaPi 27-01-2023 Verifico que no quede ningun medicamento con igual monodroga y distinta cobertura sin informar, si queda alguno, hay que solicitar que se verifique

select INTO rverifica mnroregistro,nomenclado,idmonodroga,monnombre as droga_siges,idlaboratorio,mtroquel,mcodbarra,concat(mnombre,' ',mpresentacion) as nombrecomercial_siges,vdescripcion,fdescripcion
,multiplicador
from manextra natural join medicamento natural join vias natural join formas natural join monodroga
JOIN plancoberturafarmacia USING(idmonodroga)
LEFT JOIN (SELECT codalfabeta::integer as mnroregistro FROM medicam_anticonceptivos_borrar WHERE nullvalue(mafechaproceso)) as medicam_anticonceptivos_borrar 
USING(mnroregistro)
where  nullvalue(fechafinvigencia) 
AND nullvalue(medicam_anticonceptivos_borrar.mnroregistro)
AND idmonodroga IN (
SELECT idmonodroga

					FROM (
						select idmonodroga,monnombre,drogas_mas_asociaciones,droga,nombre_comercial,manuevomultiplicador,mafechaproceso
							from medicam_anticonceptivos_borrar
							JOIN medicamento ON codalfabeta = mnroregistro
							JOIN manextra USING (mnroregistro)
							JOIN monodroga USING (idmonodroga)
                                                         WHERE  nullvalue(mafechaproceso)
							) as paracambiar
							LEFT JOIN (SELECT * FROM plancoberturafarmacia WHERE nullvalue(fechafinvigencia)) as plancoberturafarmacia USING(idmonodroga)
							WHERE multiplicador <> round((manuevomultiplicador/100.0)::numeric,2)
)
order by idmonodroga;

IF FOUND THEN 
     RAISE EXCEPTION 'R-001, Existe al menos 1 medicamento que hay que controlar, sacar el excel usando la consulta.  %',rverifica;

END IF;



--MaLaPi 25-01-2023 Siempre que se tocan las coberturas, lo mejor es limpiar la tabla base que se usa para observer

delete from sys_cobertura_farmacia;

UPDATE medicam_anticonceptivos_borrar SET mafechaproceso = now(),maerror=' Error, No se encontro la monodroga para el medicamento ' 
WHERE (nullvalue(codalfabeta) OR codalfabeta = 'NULL') AND  nullvalue(mafechaproceso);

UPDATE  medicam_anticonceptivos_borrar SET idmonodrogaalfabeta = idmonodroga 
FROM (
select idmonodroga,mnroregistro,monnombre,drogas_mas_asociaciones,droga,nombre_comercial,manuevomultiplicador,mafechaproceso
from medicam_anticonceptivos_borrar
JOIN medicamento ON codalfabeta = mnroregistro
JOIN manextra USING (mnroregistro)
JOIN monodroga USING (idmonodroga)
) as t
WHERE t.mnroregistro = medicam_anticonceptivos_borrar.codalfabeta
AND nullvalue(idmonodrogaalfabeta)
AND  nullvalue(medicam_anticonceptivos_borrar.mafechaproceso);


    OPEN cursormono;
    FETCH cursormono INTO rmono;
    WHILE  found LOOP
	
	    IF rmono.nuevacobertura = rmono.multiplicador THEN
			UPDATE medicam_anticonceptivos_borrar SET mafechaproceso = now(),maerror=' Error, No esta cambiando la Cobertura, es la misma' 
			WHERE idmonodrogaalfabeta = rmono.idmonodroga AND nullvalue(mafechaproceso); 
		ELSE

			UPDATE plancoberturafarmacia SET fechafinvigencia = now() 
			WHERE idmonodroga = rmono.idmonodroga AND nullvalue(fechafinvigencia);
           	insert into plancoberturafarmacia(idmonodroga,fechafinvigencia,multiplicador)
           	values(rmono.idmonodroga,null,rmono.nuevacobertura);
			
			UPDATE medicam_anticonceptivos_borrar SET mafechaproceso = now() WHERE idmonodrogaalfabeta = rmono.idmonodroga AND nullvalue(mafechaproceso); 
		END IF;	
          
    FETCH cursormono into rmono;
    END LOOP;
    close cursormono;

return 'true';
END;
$function$
