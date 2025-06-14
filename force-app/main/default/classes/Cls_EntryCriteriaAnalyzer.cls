/**
* Cls_EntryCriteriaAnalyzer es una clase que evalúa si un registro cumple con 
* ciertos criterios definidos para determinar su aplicabilidad a un Customer Journey.
*/
public with sharing class Cls_EntryCriteriaAnalyzer {

	/**
	 * Evalúa si un registro SObject cumple con los criterios especificados.
	 *
	 * @param record El registro SObject a evaluar.
	 * @param criteria Una cadena que representa los criterios, separados por '|'.
	 * @return true si el registro cumple con todos los criterios, false en caso contrario.
	 */
	public static Boolean doesRecordApply(SObject record, String criteria) {
		List<String> criteriaLines = criteria.split('\\|');
		for (String line : criteriaLines) {

			if(line.contains(' OR ')){

				Boolean hasAtLeastOneCriteriaPassed = false;

				for(String lineOr : line.split(' OR ')){
					if(doesRecordApply(record, lineOr)){
						hasAtLeastOneCriteriaPassed = true;
					}
				}
				if (!hasAtLeastOneCriteriaPassed) return false;
			}
			else{
				List<String> parts = line.split(';');
				if (parts.size() != 4) {
					// Criterio mal formado
					return false;
				}
				String fieldType = parts[0];
				String fieldName = parts[1];
				String operator = parts[2];
				String value = parts[3];
				
				if (!evaluateCriterion(record, fieldType, fieldName, operator, value)) {
					return false;
				}
			}
			

		}
		return true;
	}
 
	/**
	 * Evalúa un único criterio sobre un registro SObject.
	 *
	 * @param record El registro SObject a evaluar.
	 * @param fieldType El tipo de campo (e.g., String, Integer).
	 * @param fieldName El nombre del campo en el SObject.
	 * @param operator El operador de comparación (e.g., equals, greaterThan).
	 * @param value El valor contra el cual se evalúa el campo.
	 * @return true si el criterio se cumple, false en caso contrario.
	 */
	private static Boolean evaluateCriterion(SObject record, String fieldType, String fieldName, String operator, String value) {
		Object fieldValue = getFieldValue(record, fieldName);
 
		if (value.equalsIgnoreCase('NotNull')) {
			if(operator.toLowerCase().equals('equals')) return fieldValue != null;
			else if(operator.toLowerCase().equals('notEquals')) return fieldValue == null;
		}
		if (value.equalsIgnoreCase('Null')) {
			if(operator.toLowerCase().equals('equals')) return fieldValue == null;
			else if(operator.toLowerCase().equals('notEquals')) return fieldValue != null;
		}
 
		if (fieldValue == null) {
			return false;
		}
 
		Object convertedValue = convertValue(fieldType, value, fieldValue);
 
		switch on operator.toLowerCase() {
			when 'equals' {
				if(fieldType.toLowerCase().equals('sobjecttype')) return value == convertedValue;
				return fieldValue == convertedValue;
			}
			when 'notequals' {
				if(fieldType.toLowerCase().equals('sobjecttype')) return value != convertedValue;
				return fieldValue != convertedValue;
			}
			when 'in' {
				if (fieldValue instanceof String) {
					return ((String) value).split(',').contains((String) fieldValue);
				} else {
					// Error: El operador IN solo soporta campos String
					return false;
				}
			}
			when 'contains' {

				if (fieldValue instanceof String) {
					for (string variable : ((String) value).split(',')) {
						if (((String) fieldValue).contains(variable)) {
							return true;
						}
					}
				}
				return false;
			}
			when 'notin' {
				if (fieldValue instanceof String) {
					return !((String) value).split(',').contains((String) fieldValue);
				} else {
					// Error: El operador NOT IN solo soporta campos String.
					return false;
				}
			}
			when 'greaterthan' {
				return ((Decimal) fieldValue) > ((Decimal) convertedValue);
			}
			when 'lessthan' {
				return ((Decimal) fieldValue) < ((Decimal) convertedValue);
			}
			when 'greaterorequals' {
				return ((Decimal) fieldValue) >= ((Decimal) convertedValue);
			}
			when 'lessorequals' {
				return ((Decimal) fieldValue) <= ((Decimal) convertedValue);
			}
			when 'after' {
				return ((DateTime) fieldValue) > ((DateTime) convertedValue);
			}
			when 'before' {
				return ((DateTime) fieldValue) < ((DateTime) convertedValue);
			}
			when 'onorafter' {
				return ((DateTime) fieldValue) >= ((DateTime) convertedValue);
			}
			when 'onorbefore' {
				return ((DateTime) fieldValue) <= ((DateTime) convertedValue);
			}
			when else {
				// Error: Operador no soportado.
				return false;
			}
		}
	}
 
	/**
	 * Convierte un valor de cadena a su tipo correspondiente basado en el tipo de campo.
	 *
	 * @param fieldType El tipo de campo (e.g., String, Integer).
	 * @param value La cadena de valor a convertir.
	 * @return El valor convertido como un objeto del tipo apropiado.
	 */
	private static Object convertValue(String fieldType, String value, Object fieldValue) {
		switch on fieldType.toLowerCase() {
			when 'string' {
				return value;
			}
			when 'boolean' {
				return Boolean.valueOf(value);
			}
			when 'decimal' {
				return Decimal.valueOf(value);
			}
			when 'integer' {
				return Integer.valueOf(value);
			}
			when 'datetime' {
				if (value.equalsIgnoreCase('TOMORROW')) {
					return DateTime.valueOf(DateTime.now().date().addDays(1)); 
				}
				return DateTime.valueOf(value);
			}
			when 'date' {
				if (value.equalsIgnoreCase('TOMORROW')) {
					return Date.valueOf(Date.today().addDays(1)); 
				}
				return Date.valueOf(value);
			}
			when 'sobjecttype'{
				Id relatedFieldId = (Id) fieldValue;
				System.debug('RELATED OBJ NAME: ' + relatedFieldId.getSObjectType().getDescribe().getName());
				return relatedFieldId.getSObjectType().getDescribe().getName();
			}
			when else {
				// Error: Tipo de campo no soportado.
				return null;
			}
		}
	}
 
	/**
	 * Obtiene el valor de un campo de un SObject, manejando campos relacionados.
	 *
	 * @param obj El SObject del cual obtener el valor del campo.
	 * @param field El nombre del campo, que puede incluir relaciones.
	 * @return El valor del campo como un objeto, o null si ocurre un error.
	 */
	private static Object getFieldValue(SObject obj, String field) {
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

	// Método para obtener el nombre del objeto relacionado de forma dinámica
	public static String getRelatedObjectName(SObject record, String fieldName) {
		try {
			// Obtenemos la descripción del objeto
			Schema.SObjectType sObjectTypeRecord = record.getSObjectType();
			if (sObjectTypeRecord == null) {
				// ERROR ('Objeto no encontrado: ' + record);
			}
			
			// Obtenemos la descripción del campo
			Schema.DescribeFieldResult fieldDescribe = sObjectTypeRecord.getDescribe().fields.getMap().get(fieldName).getDescribe();
			
			// Obtenemos los objetos relacionados
			List<Schema.SObjectType> referenceTo = fieldDescribe.getReferenceTo();
			
			// Devolvemos el nombre del primer objeto relacionado (o vacío si no es un Lookup)
			return referenceTo.isEmpty() ? null : referenceTo[0].getDescribe().getName();

		} catch (Exception e) {
			System.debug('Error al obtener el objeto relacionado: ' + e.getMessage());
			return null;
		}
	}
 }