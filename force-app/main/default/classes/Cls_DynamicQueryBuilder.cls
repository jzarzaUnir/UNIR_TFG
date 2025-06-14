/**
* Cls_DynamicQueryBuilder es una clase que permite construir consultas SOQL dinámicas
* en Salesforce. Proporciona métodos para añadir campos, subconsultas, cláusulas TYPEOF,
* condiciones, ordenación y límites de registros.
**/
public with sharing class Cls_DynamicQueryBuilder {
   private String baseObject; // Objeto principal de la query
   private Set<String> fields; // Campos seleccionados
   private Set<Cls_DynamicQueryBuilder> subQueries; // Subqueries asociadas
   private List<String> typeOfStatements; // Cláusulas TYPEOF
   private Map<String,String> conditionalSentence;
   private String logicalOperator; 
   private String orderBy; // Ordenación
   private Integer limitRecords; // Límite de registros
   private Map<String, Object> bindVariables; // Variables de enlace

   /**
	* Constructor de la clase Cls_DynamicQueryBuilder.
	*
	* @param baseObject El nombre del objeto principal sobre el cual se construirá la consulta.
	*/
   public Cls_DynamicQueryBuilder(String baseObject) {
	   this.baseObject = baseObject;
	   this.fields = new Set<String>();
	   this.subQueries = new Set<Cls_DynamicQueryBuilder>();
	   this.typeOfStatements = new List<String>();
	   this.bindVariables = new Map<String, Object>();
	   this.conditionalSentence = new Map<String, String>();
   }

   /**
	* Añade un campo a la lista de selección de la consulta.
	*
	* @param fieldName El nombre del campo a añadir.
	* @return La instancia actual de Cls_DynamicQueryBuilder.
	*/
   public Cls_DynamicQueryBuilder addField(String fieldName) {
	   fields.add(fieldName);
	   return this;
   }

   /**
	* Añade múltiples campos a la lista de selección de la consulta.
	*
	* @param fieldNames Una lista de nombres de campos a añadir.
	* @return La instancia actual de Cls_DynamicQueryBuilder.
	*/
   public Cls_DynamicQueryBuilder addFields(List<String> fieldNames) {
	   fields.addAll(fieldNames);
	   return this;
   }

   /**
	* Añade una subconsulta a la consulta principal.
	*
	* @param subQuery Una instancia de Cls_DynamicQueryBuilder que representa la subconsulta.
	* @return La instancia actual de Cls_DynamicQueryBuilder.
	*/
   public Cls_DynamicQueryBuilder addSubQuery(Cls_DynamicQueryBuilder subQuery) {
	   subQueries.add(subQuery);
	   return this;
   }

   /**
	* Añade una cláusula TYPEOF a la consulta.
	*
	* @param baseField El campo base para la cláusula TYPEOF.
	* @param typeConditions Un mapa que define las condiciones WHEN y los campos THEN.
	* @return La instancia actual de Cls_DynamicQueryBuilder.
	*/
   public Cls_DynamicQueryBuilder addTypeOf(String baseField, Map<String, List<String>> typeConditions) {
	   String typeOfQuery = 'TYPEOF ' + baseField;
	   for (String whenCondition : typeConditions.keySet()) {
		   List<String> fields = typeConditions.get(whenCondition);
		   typeOfQuery += ' WHEN ' + whenCondition + ' THEN ' + String.join(fields, ', ');
	   }
	   typeOfQuery += ' END';
	   typeOfStatements.add(typeOfQuery);
	   return this;
   }

   /**
	* Añade una condición a la consulta.
	*
	* @param order El orden de la condición.
	* @param condition La condición a aplicar.
	* @return La instancia actual de Cls_DynamicQueryBuilder.
	*/
   public Cls_DynamicQueryBuilder addConditionSentence(String order, String condition) {
	   conditionalSentence.put(order,condition);
	   return this;
   }

   /**
	* Establece los operadores lógicos para las condiciones de la consulta.
	*
	* @param operatorSentence La cadena que representa los operadores lógicos.
	* @return La instancia actual de Cls_DynamicQueryBuilder.
	*/
   public Cls_DynamicQueryBuilder setLogicalOperators(String operatorSentence) {
	   logicalOperator = operatorSentence;
	   return this;
   }

   /**
	* Establece la cláusula ORDER BY para la consulta.
	*
	* @param orderByClause La cláusula ORDER BY.
	* @return La instancia actual de Cls_DynamicQueryBuilder.
	*/
   public Cls_DynamicQueryBuilder setOrderBy(String orderByClause) {
	   this.orderBy = orderByClause;
	   return this;
   }

   /**
	* Establece un límite en el número de registros devueltos por la consulta.
	*
	* @param limitNumber El número máximo de registros a devolver.
	* @return La instancia actual de Cls_DynamicQueryBuilder.
	*/
   public Cls_DynamicQueryBuilder setLimit(Integer limitNumber) {
	   this.limitRecords = limitNumber;
	   return this;
   }

   /**
	* Añade una variable de enlace a la consulta.
	*
	* @param key La clave de la variable de enlace.
	* @param value El valor de la variable de enlace.
	* @return La instancia actual de Cls_DynamicQueryBuilder.
	*/
   public Cls_DynamicQueryBuilder addBindVariable(String key, Object value) {
	   bindVariables.put(key, value);
	   return this;
   }

   /**
	* Genera la consulta SOQL como una cadena de texto.
	*
	* @return La consulta SOQL generada.
	*/
   public String buildQuery() {
	   String query = 'SELECT ' + String.join(new List<String>(fields), ', ');

	   if (!typeOfStatements.isEmpty()) {
		   query += ', ' + String.join(typeOfStatements, ', ');
	   }

	   // Añadir subqueries
	   if (!subQueries.isEmpty()) {
		   for (Cls_DynamicQueryBuilder subQuery : subQueries) {
			   query += ', (' + subQuery.buildQuery() + ')';
		   }
	   }

	   query += ' FROM ' + baseObject;

	   if(!conditionalSentence.isEmpty()){
		   for(String order : conditionalSentence.keySet()){
			   logicalOperator = logicalOperator.replace(order,conditionalSentence.get(order));
		   }
   
		   query += ' WHERE ' + logicalOperator;
	   }

	   if (orderBy != null) {
		   query += ' ORDER BY ' + orderBy;
	   }

	   if (limitRecords != null) {
		   query += ' LIMIT ' + limitRecords;
	   }

	   return query;
   }

   /**
	* Ejecuta la consulta SOQL generada y devuelve los resultados.
	*
	* @return Una lista de SObjects resultantes de la ejecución de la consulta.
	*/
   public List<SObject> executeQuery() {
	   String query = buildQuery();
	   System.debug(query);
	   return Database.queryWithBinds(query, bindVariables, AccessLevel.USER_MODE);
   }
}