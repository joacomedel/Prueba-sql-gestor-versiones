CREATE OR REPLACE FUNCTION public.w_emitirconsumoafiliado_consultas(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$/*
*{"NroAfiliado":"28272137","Barra":30,"uwnombre":"usudesa",NroDocumento":null,"TipoDocumento":null,"Track":null,"token":"XXZZZZ"
,"info_consumio_token":"Expendio Web","Asociacion":"NEUQUEN/RIO NEGRO","PlanCobertura":"1" }
*/
DECLARE
       respuestajson jsonb;
       vparametro jsonb;
       vpracticas jsonb;
       vprestador jsonb;

begin

	vpracticas = '{ "ConsumosWeb":[{"CodigoConvenio":"12.42.01.01","DescripcionCodigoConvenio":"Consulta"}]}';
	vprestador = '{"ApellidoEfector":null,"NombreEfector":null,"CuilEfector":"30590509643","Diagnostico":null,"FechaConsumo":null,"MatriculaEfector":null ,"CategoriaEfector":"A"}';
                       
	SELECT INTO vparametro replace(  (parametro::text || vprestador::text), 
		'}{', 
		', ')::jsonb; 

	SELECT INTO vparametro replace(  (vparametro::text || vpracticas::text), 
		'}{', 
		', ')::jsonb; 
      SELECT INTO respuestajson * FROM w_emitirconsumoafiliado_token(vparametro);
      return respuestajson;

end;$function$
