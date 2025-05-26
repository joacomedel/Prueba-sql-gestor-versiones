CREATE OR REPLACE FUNCTION public.w_validarordenissn(parametro jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$


DECLARE
       respuestajson jsonb;
       respuestajson_info jsonb;
       jsonafiliado jsonb;
       jsonconsumo jsonb;
       carticulo refcursor;


       /*
       $param = array(
                        'url'=>$data['url'],
                        'metodo'=>$data['metodo'],
                        'param' => array( "Userkey" => $data['param']['Userkey'],
                                          "Cuilkey" => $data['param']['Cuilkey'],
                                          "Passkey" => $data['param']['Passkey'],
                                          "Codaplicacion" => $data['param']['Codaplicacion'],
                                          "Numafiliado" => $data['param']['Numafiliado'],
                                          "Fecpresta" => $data['param']['Fecpresta'])
                    );
       */
	
BEGIN
     --RAISE NOTICE 'parametros %',parametro;
     --respuestajson_info =concat('{ "url":"http://preprod.issn.gov.ar/webservicesentidaddesa/servlet/com.webservicesentidaddesa.anewautorizacionyconsumo?wsdl","metodo":"Execute","param":[{"Userkey":"","Cuilkey":"HEnP5HGtU3eTTcd8V6dwTA==","Passkey":"zDEC01wQBhQ+RkqYsuJpEQ==","Codaplicacion":"134","NumeroProveedor":"1661","Numerosucursal":"1","Numeroresponsablefacturacion":"129","Delegacion":"6","Matriculaprescriptor":"4562","Provinciamatriculaprescriptor":"1","Especialidadmatriculaprescriptor":"8","Matriculaefector":"","Provinciamatriculaefector":"","Especialidadmatriculaefector":"","Categoriaefector":"","Mutual":"","Porcentajecoseguromutual":"","Numeroafiliado":"25175134","Gravamen":"1","Tipoprestacion":"M","Nroexpediente":"0","Ordeninternacion":"0","Nrotoken":"","Fechaprescripcion":"2022-09-20","Ambulatorio":"","Medicamentos":[{"CodigoMedic":"30069","MedicTroquel":"2844722","MedicCodBarras":"7795347942689 ","GravamenMedi":"1","CodigoOperacion":"V","CantidadMedic":"2","AuDMNumExp_Numero_Expediente":"7101"}]}]}');	
     
    --respuestajson =respuestajson_info;
	respuestajson =parametro;

	--respuestajson=respuestajson_info;





	return respuestajson;

END;
$function$
