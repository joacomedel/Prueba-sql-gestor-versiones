CREATE OR REPLACE FUNCTION public.excluye_esquemas()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
	tabla record;
	tablas_quitar CURSOR FOR
		SELECT concat(esquemasasincronizar.nombre,'.',tablasasincronizar.nombre) AS id_tabla
		FROM esquemasasincronizar , tablasasincronizar;
	contador integer := 0;
	set_rep text;
	pos integer;
	esquema varchar(50);

BEGIN				
	FOR tabla IN tablas_quitar LOOP		
	
		--Para evitar un esquema, si no se necesita quitar las siguientes 3 lineas y el if
		pos := position ('.' in tabla.id_tabla);
		esquema := substring (tabla.id_tabla from 0 for pos);
		RAISE NOTICE 'Tabla: %, Esquema %', tabla.id_tabla, esquema;
		if (esquema != 'sanatorio') then
	
			SELECT * INTO set_rep FROM bdr.table_get_replication_sets(tabla.id_tabla);
			RAISE NOTICE 'Antes exclusión Tabla: %, Set de Replicación: %',tabla.id_tabla, set_rep;
		
			PERFORM bdr.table_set_replication_sets(tabla.id_tabla,'{}');
		
			SELECT * INTO set_rep FROM bdr.table_get_replication_sets(tabla.id_tabla);
			RAISE NOTICE 'Después exclusión Tabla: %, Set de Replicación: %',tabla.id_tabla, set_rep;	
		
			contador := contador + 1;
		end if;
	END LOOP;			
	RAISE NOTICE 'Contador = %',contador;
	RETURN 'true';
END;
$function$
