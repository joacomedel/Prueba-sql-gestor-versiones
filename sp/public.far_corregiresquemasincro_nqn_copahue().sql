CREATE OR REPLACE FUNCTION public.far_corregiresquemasincro_nqn_copahue()
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$DECLARE

     respuesta boolean; 

BEGIN
	--Se eliminan los datos que no deben ser cargados en nqn.
	--Select INTO respuesta * FROM limpiarsincrocopahueparcial();
	--Se corrigen los articulos.
	Select INTO respuesta * FROM far_corregir_nqn_copahuearticulo();
	--Se corrigen los precios. 
	--Select INTO respuesta * FROM far_corregircopahueprecioarticulo();
	--Se corrigen los afiliados.
	--SELECT INTO respuesta * FROM far_corregircopahueafiliados();

	--Se sincronizan los esquemas
	--SELECT INTO respuesta * FROM sincronizaresquemas();
      
return respuesta;
END;
$function$
