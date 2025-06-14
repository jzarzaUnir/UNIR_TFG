/**
* Cls_APIsOrchestrator es una clase que implementa un proceso Batchable en Salesforce,
* diseñado para orquestar la ejecución de APIs basadas en criterios definidos en 
* metadatos personalizados. También permite realizar llamadas externas.
*/
public with sharing class Cls_APIsOrchestrator{
	private Set<Id> recordsIds; // Registros procesados desde el Trigger
	private String sObjectName;
	private List<CustomerJourneys__mdt> customMetadataEntries = new List<CustomerJourneys__mdt>();
	private Map<String,Map<String,String>> mapCustomMetadataWithJson = new Map<String,Map<String,String>>();
	private static List<Error__c> errorList = new List<Error__c>(); // Lista para acumular errores
 
    public Cls_APIsOrchestrator(List<SObject> records, String sObjectName, Boolean isInsert) {
        this.recordsIds = (new Map<Id, SObject>(records)).keySet();
        this.sObjectName = sObjectName;
        String triggerAction = isInsert ? 'Created' : 'Updated';
    
        List<CustomerJourneys__mdt> allEntries = [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, SystemModstamp, JSON__c, Entry_Criteria__c, Trigger_Actions__c, Object__c, Endpoint__c, Subject__c, TemplateId__c, Active__c FROM CustomerJourneys__mdt ];
        this.customMetadataEntries = new List<CustomerJourneys__mdt>();
    
        for (CustomerJourneys__mdt entry : allEntries) {
            if (entry.Object__c == sObjectName &&
                entry.Trigger_Actions__c != null &&
                entry.Trigger_Actions__c.contains(triggerAction)) {
                this.customMetadataEntries.add(entry);
            }
        }
    }
 
 
	/**
	 * Procesa los registros en lotes. Se llama para cada lote de registros.
	 *
	 * @param bc Contexto del batch.
	 * @param records Lista de registros SObject a procesar en el lote actual.
	 */
	public void executeOrchestrator() {
		Map<String,List<String>> mapJsons;
		Map<String,List<SObject>> mapMetadataObjects = new Map<String,List<SObject>>();
		List<Orchestrator_Queue__c> orchestratorList = new List<Orchestrator_Queue__c>();
		List<SObject> recordList;

		try{
			if(!this.customMetadataEntries.isEmpty()) {
				recordList = Cls_APIsOrchestratorHandler.generateQuery(this.customMetadataEntries, this.sObjectName, this.recordsIds);
			}
		} catch (Exception e) {
			// Agregar el error a la lista utilizando Cls_ErrorHandler
			Cls_ErrorHandler.insertError(e.getMessage(), 'ERR_START', Cls_ErrorHandler.STR_ERROR_SALESFORCE, e.getLineNumber(), 'Cls_APIsOrchestrator', 'start', null);
		}

		this.mapCustomMetadataWithJson = Cls_APIsOrchestratorHandler.mapMetadata(this.customMetadataEntries);

		System.debug('LISTADO DE REGISTROS' + recordList);
		
		if(recordList != null && !recordList.isEmpty()){
			for (SObject record : recordList) {
				try {
					for (CustomerJourneys__mdt metadata : this.customMetadataEntries) {
						if (Cls_EntryCriteriaAnalyzer.doesRecordApply(record, metadata.Entry_Criteria__c)) {
							if(mapMetadataObjects.get(metadata.DeveloperName) != null){
								List<SObject> recordsToApply = mapMetadataObjects.get(metadata.DeveloperName);
								recordsToApply.add(record);
								mapMetadataObjects.put(metadata.DeveloperName, recordsToApply);
							}
							else {
								mapMetadataObjects.put(metadata.DeveloperName, new List<SObject>{record});
							}
							orchestratorList.add(new Orchestrator_Queue__c(
									CustomerJourney__c = metadata.Id,
									ObjectName__c = String.valueOf(record.Id.getSObjectType()),
									RecordId__c = record.Id,
									Status__c = 'Pending',
									JSON__c = generateJson(record, metadata)
									)
							);
							break;
						}
					}
					System.debug('LISTADO DE REGISTROS APLICABLES A LANZAR' + mapMetadataObjects);
				} catch (Exception e) {
					// Agregar el error a la lista utilizando Cls_ErrorHandler
					Cls_ErrorHandler.insertError(e.getMessage(), 'ERR_EXECUTE', Cls_ErrorHandler.STR_ERROR_SALESFORCE, e.getLineNumber(), 'Cls_APIsOrchestrator', 'execute', null);
				}
			}

			if(!orchestratorList.isEmpty()){
				try{
					insert orchestratorList;
				} catch(Exception e){
					Cls_ErrorHandler.insertError(e.getMessage(), 'ERR_EXECUTE', Cls_ErrorHandler.STR_ERROR_SALESFORCE, e.getLineNumber(), 'Cls_APIsOrchestrator', 'execute', null);
				}
			}
		}
	}

	public String generateJson(SObject record, CustomerJourneys__mdt customerJourney){

		Cls_DynamicJSONGenerator jsonGenerator = new Cls_DynamicJSONGenerator();
		jsonGenerator.createJsonObject(record, this.mapCustomMetadataWithJson.get(customerJourney.DeveloperName), null);
		return jsonGenerator.retriveJson();
	}
}