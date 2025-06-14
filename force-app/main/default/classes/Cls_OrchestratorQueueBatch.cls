global class Cls_OrchestratorQueueBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts {

	List< Error__c > errorList = new List<Error__c>();
	List<OrchestratorWrapper> listRequests = new List<OrchestratorWrapper>();
	
	global Database.QueryLocator start(Database.BatchableContext bc) {
		// Consulta para obtener los registros pendientes
		return Database.getQueryLocator([
			SELECT Id, ObjectName__c, RecordId__c, Status__c, CustomerJourney__c, ContactKey__c, JSON__c 
			FROM Orchestrator_Queue__c 
			WHERE Status__c = 'Pending'
			ORDER BY CustomerJourney__c
		]);
	}
	
	global void execute(Database.BatchableContext bc, List<SObject> scope) {
		// Map para agrupar los JSONs por Customer Journey
		Map<String, List<String>> mapCustomerJourneyWithJSONs = new Map<String, List<String>>();
		Map<String, List<Orchestrator_Queue__c>> mapCustomerJorneyWithOrchestratorQueue = new Map<String, List<Orchestrator_Queue__c>>();
		Map<String, String> mapJsons = new Map<String, String>();

		if(!scope.isEmpty()){
			// Casteamos los registros del scope a Orchestrator_Queue__c
			List<Orchestrator_Queue__c> ListRecordsToSFMC = (List<Orchestrator_Queue__c>) scope;
			
			// Agrupamos los JSONs por CustomerJourney__c
			for (Orchestrator_Queue__c recordToSend : ListRecordsToSFMC) {
				if (!mapCustomerJourneyWithJSONs.containsKey(recordToSend.CustomerJourney__c)) {
					mapCustomerJourneyWithJSONs.put(recordToSend.CustomerJourney__c, new List<String>());
				}
				mapCustomerJourneyWithJSONs.get(recordToSend.CustomerJourney__c).add(recordToSend.JSON__c);

				if (!mapCustomerJorneyWithOrchestratorQueue.containsKey(recordToSend.CustomerJourney__c)) {
					mapCustomerJorneyWithOrchestratorQueue.put(recordToSend.CustomerJourney__c, new List<Orchestrator_Queue__c>());
				}
				mapCustomerJorneyWithOrchestratorQueue.get(recordToSend.CustomerJourney__c).add(recordToSend);
			}

			if(!mapCustomerJourneyWithJSONs.isEmpty()){
				// Obtener la configuración de Customer Journeys desde Metadata
				Map<Id, CustomerJourneys__mdt> customerJourneys = new Map<Id, CustomerJourneys__mdt>(
					[SELECT Id, Endpoint__c, Subject__c, TemplateId__c
					FROM CustomerJourneys__mdt 
					WHERE Id IN :mapCustomerJourneyWithJSONs.keySet()]
				);

				// Generación del JSON estructurado por Customer Journey
				for (String idJourney : mapCustomerJourneyWithJSONs.keySet()) {
					if (customerJourneys.containsKey(idJourney)) {
						CustomerJourneys__mdt customerJourney = customerJourneys.get(idJourney);
						
						Cls_DynamicJSONGenerator jsonGeneral = new Cls_DynamicJSONGenerator();
						// API KEY = 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
						jsonGeneral.startObject();

						jsonGeneral.addFieldName('sender');
						jsonGeneral.startObject();
						jsonGeneral.addFieldAndValue('email', UserInfo.getUserEmail());
						jsonGeneral.addFieldAndValue('name', UserInfo.getFirstName());
						jsonGeneral.endObject();

						jsonGeneral.addFieldAndValue('subject', customerJourney.Subject__c);
						jsonGeneral.addFieldAndIntValue('templateId', Integer.valueOf(customerJourney.TemplateId__c));

						jsonGeneral.startArray('messageVersions');
						jsonGeneral.startObject();

						jsonGeneral.startArray('to');
						for (String jsonRecord : mapCustomerJourneyWithJSONs.get(idJourney)) {
							try {
								Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonRecord);
								jsonGeneral.writeObject(jsonMap);
							} catch (Exception e) {
								Cls_ErrorHandler.addErrorToList(this.errorList,
									e.getMessage(), 'ERR_JSON', Cls_ErrorHandler.STR_ERROR_SALESFORCE, 
									e.getLineNumber(), 'Cls_OrchestratorQueueBatch', 'execute.createJsonObject', null
								);
							}
						}
						jsonGeneral.closeArray();
						jsonGeneral.endObject();
						jsonGeneral.closeArray();
						String finalJson = jsonGeneral.retriveJson();
						System.debug(finalJson);

						// Almacenar JSON agrupado por endpoint
						OrchestratorWrapper ow = new OrchestratorWrapper(customerJourney.Endpoint__c, finalJson, mapCustomerJorneyWithOrchestratorQueue.get(customerJourney.Id));
						listRequests.add(ow);
					}
				}
			}
		}
	}

	global void finish(Database.BatchableContext bc) {
		
		// Enviar los JSONs a Brevo si es necesario
		if(listRequests != null && !listRequests.isEmpty()) {
			Database.executeBatch(new Cls_OrchestratorBatchSender(listRequests),1);
		}
		Cls_ErrorHandler.insertListErrors(this.errorList);
	}
	public class OrchestratorWrapper {

		public String endpoint;
		public String jsonPayload;
		public List<Orchestrator_Queue__c> listOrchestratorQueue;

		public OrchestratorWrapper(String endpoint, String jsonPayload, List<Orchestrator_Queue__c> listOrchestratorQueue){
			this.endpoint = endpoint;
			this.jsonPayload = jsonPayload;
			this.listOrchestratorQueue = listOrchestratorQueue;
		}

	}
}