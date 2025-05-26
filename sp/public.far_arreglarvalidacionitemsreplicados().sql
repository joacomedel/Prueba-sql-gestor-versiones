CREATE OR REPLACE FUNCTION public.far_arreglarvalidacionitemsreplicados()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$declare
 --CURSOR
  cvalitem refcursor;
  
--RECORD
  rvalitem RECORD;
  rvalidacionitem  RECORD;
--VARIABLES
  resp BOOLEAN;
begin

resp = true;
OPEN cvalitem FOR SELECT count(*),fincodigo ,fechareceta,idvalidacion, idcentrovalidacion, codbarras
	from far_validacion natural join far_validacionitems
	where idcentrovalidacion=99 and not nullvalue(idvalidacion) and not nullvalue(fechareceta)
	group by fincodigo, fechareceta, idvalidacion, idcentrovalidacion, codbarras
	having count(*)>1
	order by idvalidacion;  

 FETCH cvalitem into rvalitem;
 WHILE  found LOOP

	SELECT INTO rvalidacionitem idcentrovalidacionitem,MAX(idvalidacionitem) as idvalidacionitem FROM far_validacionitems 
		WHERE idvalidacion = rvalitem.idvalidacion AND codbarras ilike rvalitem.codbarras
		GROUP BY idcentrovalidacionitem;

        DELETE FROM  far_validacionitems WHERE idvalidacionitem <> rvalidacionitem.idvalidacionitem AND idcentrovalidacionitem =rvalidacionitem.idcentrovalidacionitem AND idvalidacion =  rvalitem.idvalidacion AND codbarras ilike rvalitem.codbarras;
 	

 FETCH cvalitem into rvalitem;
 END LOOP;
 close cvalitem;

RETURN resp;     
END;

$function$
