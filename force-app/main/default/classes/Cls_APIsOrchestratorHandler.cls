/**
* Cls_APIsOrchestratorHandler es una clase auxiliar que proporciona métodos 
* para generar consultas dinámicas y manejar metadatos personalizados en el contexto 
* de la orquestación de APIs.
**/
public class Cls_APIsOrchestratorHandler {
	
	/**
	 * Genera una consulta SOQL dinámica basada en los metadatos personalizados y registros proporcionados.
	 *
	 * @param customMetadataEntries Lista de entradas de metadatos personalizados.
	 * @param sObjectName El nombre del objeto sobre el cual se ejecutará la consulta.
	 * @param records Conjunto de IDs de registros a incluir en la consulta.
	 * @return Una lista de SObjects resultantes de la ejecución de la consulta.
	 */
	public static List<SObject> generateQuery(List<CustomerJourneys__mdt> customMetadataEntries, String sObjectName, Set<Id> records) {
		// Definir mapeo de campos polimórficos
		Map<String, List<String>> polymorphicMapping = new Map<String, List<String>>{
			'Who.' => new List<String>{'Lead', 'Contact'},
			'What.' => new List<String>{'Account', 'Opportunity', 'Case'},
			'Owner.' => new List<String>{'User', 'Group'},
			'Parent.' => new List<String>{'Account', 'Case', 'Solution', 'Campaign', 'Contract', 'Opportunity'}
		};

		Map<String, String> jsonMapAll = new Map<String, String>();
		List<String> fieldsToQuery = new List<String>();
		Map<String, Map<String, List<String>>> mapTypeOfFields = new Map<String, Map<String, List<String>>>();

		// Procesar metadatos personalizados
		for (CustomerJourneys__mdt customerJourney : customMetadataEntries) {
			// Procesar campos del JSON
			processJsonFields(customerJourney.JSON__c, jsonMapAll, polymorphicMapping, mapTypeOfFields, fieldsToQuery);
			
			// Procesar campos de Entry Criteria
			processEntryCriteria(customerJourney.Entry_Criteria__c, polymorphicMapping, mapTypeOfFields, fieldsToQuery);
		}

		// Construir la consulta dinámica
		Cls_DynamicQueryBuilder queryBuilder = new Cls_DynamicQueryBuilder(sObjectName).addFields(fieldsToQuery);

		// Agregar cláusulas TYPEOF
		for (String polymorphicField : mapTypeOfFields.keySet()) {

			queryBuilder.addTypeOf(polymorphicField.remove('.'), mapTypeOfFields.get(polymorphicField));
		
		}

		// Agregar condición WHERE
		queryBuilder.addConditionSentence('1', 'Id IN :ids').addBindVariable('ids', records).setLogicalOperators('1');

		return queryBuilder.executeQuery();
	}

	/**
	 * Procesa los campos definidos en el JSON del metadato personalizado.
	 *
	 * @param jsonString Cadena JSON que contiene los campos a procesar.
	 * @param jsonMapAll Mapa global de campos procesados desde el JSON.
	 * @param polymorphicMapping Mapa de campos polimórficos y sus posibles tipos relacionados.
	 * @param mapTypeOfFields Mapa que asocia campos polimórficos con sus listas de atributos relacionados.
	 * @param fieldsToQuery Lista de campos no polimórficos a incluir en la consulta.
	 */
	private static void processJsonFields(
		String jsonString, 
		Map<String, String> jsonMapAll, 
		Map<String, List<String>> polymorphicMapping, 
		Map<String, Map<String, List<String>>> mapTypeOfFields, 
		List<String> fieldsToQuery
	) {
		jsonString = jsonString.replaceAll('\\r','').replaceAll('\\n','').remove(' ').remove('{').remove('}');
		List<String> fieldRowsList = jsonString.split(',');

		for (String row : fieldRowsList) {
			String fieldName = row.split('":"')[0].replaceAll('"', '');
			String fieldApiName = row.split('":"')[1].replaceAll('"', '');
			jsonMapAll.put(fieldName, fieldApiName);

			processField(fieldName, fieldApiName, polymorphicMapping, mapTypeOfFields, fieldsToQuery);
		}
	}

	/**
	 * Procesa los criterios de entrada definidos en el metadato personalizado.
	 *
	 * @param entryCriteria Cadena que contiene los criterios de entrada a procesar.
	 * @param polymorphicMapping Mapa de campos polimórficos y sus posibles tipos relacionados.
	 * @param mapTypeOfFields Mapa que asocia campos polimórficos con sus listas de atributos relacionados.
	 * @param fieldsToQuery Lista de campos no polimórficos a incluir en la consulta.
	 */
	private static void processEntryCriteria(
		String entryCriteria, 
		Map<String, List<String>> polymorphicMapping, 
		Map<String, Map<String, List<String>>> mapTypeOfFields, 
		List<String> fieldsToQuery
	) {
		for (String line : entryCriteria.split('\\|')) {
			List<String> parts = line.split(';');
			String fieldName = parts[1];
			String fieldApiName = parts[1]; // Puede ser el mismo en este caso
			processField(fieldName, fieldApiName, polymorphicMapping, mapTypeOfFields, fieldsToQuery);
		}
	}

	 /**
	 * Procesa un campo específico para determinar si es polimórfico o no.
	 *
	 * @param fieldName Nombre del campo a procesar (puede contener relaciones).
	 * @param fieldApiName API name del campo a procesar.
	 * @param polymorphicMapping Mapa de campos polimórficos y sus posibles tipos relacionados.
	 * @param mapTypeOfFields Mapa que asocia campos polimórficos con sus listas de atributos relacionados.
	 * @param fieldsToQuery Lista de campos no polimórficos a incluir en la consulta.
	 */
	private static void processField(String fieldName, String fieldApiName, Map<String, List<String>> polymorphicMapping, Map<String, Map<String, List<String>>> mapTypeOfFields, List<String> fieldsToQuery) {
		Boolean isPolymorphic = false;

		for (String polymorphic : polymorphicMapping.keySet()) {
			if (fieldApiName.toLowerCase().contains(polymorphic.toLowerCase())) {
				isPolymorphic = true;

				Map<String, List<String>> typeOfFields = mapTypeOfFields.containsKey(polymorphic) 
					? mapTypeOfFields.get(polymorphic) 
					: new Map<String, List<String>>();

				String relatedObject = null;
				if (fieldName.contains(':')) {
					List<String> parts = fieldName.split(':');
					if (parts.size() > 2) {
						relatedObject = polymorphicMapping.get(polymorphic).contains(parts[2]) ? parts[2] : null; // Este es el valor esperado
					}
				}


				String fieldPath = fieldApiName.contains('.') ? fieldApiName.substringAfter('.') : fieldApiName;

				if (relatedObject != null) {
					// Agregar solo para el objeto específico
					if (!typeOfFields.containsKey(relatedObject)) {
						typeOfFields.put(relatedObject, new List<String>());
					}
					if(typeOfFields.get(relatedObject).isEmpty() || !typeOfFields.get(relatedObject).contains(fieldPath)) typeOfFields.get(relatedObject).add(fieldPath);
				} else {
					// Agregar para todos los objetos relacionados
					for (String relatedObj : polymorphicMapping.get(polymorphic)) {
						if (!typeOfFields.containsKey(relatedObj)) {
							typeOfFields.put(relatedObj, new List<String>());
						}
						if(typeOfFields.get(relatedObj).isEmpty() || !typeOfFields.get(relatedObj).contains(fieldPath)) typeOfFields.get(relatedObj).add(fieldPath);
					}
				}
				mapTypeOfFields.put(polymorphic, typeOfFields);
				break;
				
			}
		}

		if (!isPolymorphic && !fieldsToQuery.contains(fieldApiName)) {
			fieldsToQuery.add(fieldApiName);
		}
	}
 
	/**
	 * Obtiene el valor de un campo de un SObject, manejando campos relacionados.
	 *
	 * @param obj El SObject del cual obtener el valor del campo.
	 * @param field El nombre del campo, que puede incluir relaciones.
	 * @return El valor del campo como un objeto, o null si ocurre un error.
	 */
	public static Object getFieldValue(SObject obj, String field) {
		if(!field.contains('.')) {
			try {
				return obj.get(field);
			} catch(exception ex) {
				system.debug('******Error en ' + field + ': '+ ex.getmessage()); 
				return null;
			}
		} else {
			try {
				List<string> splitedFields = field.split('\\.');
				string fieldApiName = splitedFields[splitedFields.size()-1];
	
				for(integer i=0; i<splitedFields.size()-1; i++){
					obj = obj.getSobject(splitedFields[i]); 
				}
				
				return obj.get(fieldApiName);
			} catch(exception ex) {
				system.debug('******Error en ' + field + '  el valor esta vacio: '+ ex.getmessage()); 
				return null;
			}
		}
	}
 
	/**
	 * Mapea los metadatos personalizados a un formato de mapa que asocia nombres de desarrollador
	 * con sus configuraciones JSON.
	 *
	 * @param customMetadataEntries Lista de entradas de metadatos personalizados.
	 * @return Un mapa que asocia nombres de desarrollador con mapas de configuraciones JSON.
	 */
	public static Map<String,Map<String,String>> mapMetadata(List<CustomerJourneys__mdt> customMetadataEntries) {
		Map<String,Map<String,String>> mapCustomMetadataWithJson = new Map<String,Map<String,String>>();
 
		for(CustomerJourneys__mdt customerJourney : customMetadataEntries){
			Map<String,String> jsonMap = new Map<String,String>();
 
			String jsonString = customerJourney.JSON__c;
			
			jsonString = jsonString.replaceAll('\\r','').replaceAll('\\n','').remove(' ').remove('{').remove('}');
			List<String> fieldRowsList = jsonString.split(',');
 
			for(String row : fieldRowsList){
				jsonMap.put(row.split('":"')[0].replaceAll('"',''),row.split('":"')[1].replaceAll('"',''));
			}
 
			mapCustomMetadataWithJson.put(customerJourney.DeveloperName, jsonMap);
		}
 
		return mapCustomMetadataWithJson;
	}

 }