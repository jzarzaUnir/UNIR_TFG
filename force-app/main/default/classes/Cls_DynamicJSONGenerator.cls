/**
* Cls_DynamicJSONGenerator es una clase que facilita la generación de JSON dinámicos
* a partir de objetos SObject en Salesforce. Utiliza JSONGenerator para construir 
* estructuras JSON complejas, incluyendo relaciones entre objetos.
*/
public with sharing class Cls_DynamicJSONGenerator {

	private JSONGenerator dynamicJSON;
	private String languageDefaultValue;
 
	/**
	 * Constructor por defecto de la clase Cls_DynamicJSONGenerator.
	 * Inicializa un generador de JSON con pretty printing habilitado.
	 */
	public Cls_DynamicJSONGenerator(){
		this.dynamicJSON = JSON.createGenerator(true);
	} 
 
	/**
	 * Crea un objeto JSON a partir de un SObject dado, utilizando mapas de campos 
	 * para determinar qué propiedades incluir.
	 *
	 * @param obj El SObject del cual se generará el JSON.
	 * @param camposLista Un mapa que relaciona etiquetas de campo con nombres API de campo.
	 * @param mapCamposRelated Un mapa de mapas que define las relaciones entre campos relacionados.
	 */
	public void createJsonObject(SObject obj, Map<String,String> camposLista, Map<String,Map<String,String>> mapCamposRelated){
		startObject();
 
		for(String fieldLabel : camposLista.keySet()){
			if(mapCamposRelated != null && mapCamposRelated.get(camposLista.get(fieldLabel)) != null){
				startArray(fieldLabel);
				
				for(SObject objHijo : obj.getSObjects(camposLista.get(fieldLabel))){
					createJsonObject(objHijo,mapCamposRelated.get(camposLista.get(fieldLabel)),mapCamposRelated);
				}
 
				closeArray();
			}
			else addObjFieldToJson(fieldLabel,camposLista.get(fieldLabel), obj);
		}
 
		endObject();
	}
 
	/**
	 * Procesa un campo de relación, manejando casos polimórficos y extrayendo valores 
	 * apropiados para incluirlos en el JSON.
	 *
	 * @param fieldLabel La etiqueta del campo en el JSON.
	 * @param field El nombre API completo del campo.
	 * @param obj El SObject que contiene el campo de relación.
	 */
	public void getRelationshipField (String fieldLabel, String field, SObject obj){
		List<String> polymorphicFields = new List<String>{'Who','What','Parent','Owner','Report'};
		Boolean isPolymorphic = false;
		List<string> splitedFields = field.split('\\.');
		string fieldApiName = splitedFields[splitedFields.size()-1];
		try{
			for(integer i=0;i<splitedFields.size()-1;i++){
				obj = obj.getSobject(splitedFields[i]); 
			}
 
			for(String polymorphicField : polymorphicFields){
				if(fieldLabel.contains(polymorphicField) && fieldLabel.contains('Id')){
					isPolymorphic = true;
					break;
				}
			}
 
			if(!isPolymorphic){
				addObjFieldToJson(fieldLabel,fieldApiName,obj);
			} 
			else{
				if(fieldLabel.contains(String.valueOf(obj.getSObjectType())))  addObjFieldToJson(fieldLabel,fieldApiName,obj);
				else addFieldAndValue(fieldLabel,'');
			}
 
		}catch(exception ex){
			system.debug('******Error en ' + field + '  el valor esta vacio: '+ ex.getmessage()); 
			addFieldAndValue(fieldLabel,'');
		}
	}
 
	/**
	 * Añade un campo de un SObject al JSON, determinando el tipo de dato y 
	 * utilizando el método adecuado del JSONGenerator.
	 *
	 * @param fieldLabel La etiqueta del campo en el JSON.
	 * @param fieldApiName El nombre API del campo.
	 * @param obj El SObject que contiene el campo.
	 */
	public void addObjFieldToJson (String fieldLabel,String fieldApiName, SObject obj){
		Map<String, Schema.SObjectField> fieldMap = obj.getSObjectType().getDescribe().fields.getMap(); 
		Schema.DisplayType fieldDataType = fieldMap.get(fieldApiName)?.getDescribe().getType();
			
		if(!fieldApiName.contains('.') && obj.get(fieldApiName) != null){
			switch on fieldDataType{
				when DATE {
					Date dt = Date.valueOf(obj.get(fieldApiName));
					this.dynamicJSON.writeDateField(fieldLabel, dt); 
				}
				when CURRENCY{
					Double db = (Double) obj.get(fieldApiName);
					this.dynamicJSON.writeNumberField(fieldLabel, db);
				}
				when BOOLEAN{
					Boolean b = (Boolean) obj.get(fieldApiName);
					this.dynamicJSON.writeBooleanField(fieldLabel, b);
				}
				when STRING,PICKLIST{
					String s = (String) obj.get(fieldApiName);
					this.dynamicJSON.writeStringField(fieldLabel, s);
				}
				when EMAIL{
					String s = (String) obj.get(fieldApiName);
					this.dynamicJSON.writeStringField(fieldLabel, s);
				}
				when else{
					this.dynamicJSON.writeObjectField(fieldLabel, obj.get(fieldApiName));
				}
			}
		} else if(fieldApiName.contains('.')){
			getRelationshipField(fieldLabel,fieldApiName,obj);
		} else if(fieldLabel.endsWith('Language')) {
			if (this.languageDefaultValue != null) {
				this.dynamicJSON.writeStringField(fieldLabel, this.languageDefaultValue);
			} else {
				addFieldAndValue(fieldLabel, '');
			}
		} else {
			addFieldAndValue(fieldLabel,'');
		}
	}
 
	/**
	 * Añade un campo y su valor al JSON como un par clave-valor de tipo String.
	 *
	 * @param field El nombre del campo.
	 * @param value El valor del campo.
	 */
	public void addFieldAndValue (String field, String value){
		this.dynamicJSON.writeStringField(field, value);
	}

	/**
	 * Añade un campo y su valor al JSON como un par clave-valor de tipo Integer.
	 *
	 * @param field El nombre del campo.
	 * @param value El valor del campo.
	 */
	public void addFieldAndIntValue (String field, Integer value){
		this.dynamicJSON.writeNumberField(field, value);
	}
 
	/**
	 * Añade solo el nombre de un campo al JSON.
	 *
	 * @param field El nombre del campo.
	 */
	public void addFieldName (String field){
		this.dynamicJSON.writeFieldName(field);
	}

	/**
	 * Recupera el JSON generado como una cadena de texto.
	 * @return Una representación en cadena del JSON generado.
	 */
	public void addString(String stringValue){
		this.dynamicJSON.writeString(stringValue);
	}

	/**
	 * Recupera el JSON generado como una cadena de texto.
	 * @return Una representación en cadena del JSON generado.
	 */
	public void writeObject(Object obj){
		this.dynamicJSON.writeObject(obj);
	}
 
	/**
	 * Inicia un nuevo array en el JSON bajo el nombre de campo especificado.
	 *
	 * @param field El nombre del campo que contendrá el array.
	 */
	public void startArray (String field){
		addFieldName(field);
		this.dynamicJSON.writeStartArray();
	}
 
	/**
	 * Cierra el array actual en el JSON.
	 */
	public void closeArray (){
		this.dynamicJSON.writeEndArray();
	}
 
	/**
	 * Inicia un nuevo objeto en el JSON.
	 */
	public void startObject(){
		this.dynamicJSON.writeStartObject();
	}
 
	/**
	 * Cierra el objeto actual en el JSON.
	 */
	public void endObject(){
		this.dynamicJSON.writeEndObject();
	}
 
	/**
	 * Recupera el JSON generado como una cadena de texto.
	 * @return Una representación en cadena del JSON generado.
	 */
	public String retriveJson(){
		return this.dynamicJSON.getAsString();
	}
 }