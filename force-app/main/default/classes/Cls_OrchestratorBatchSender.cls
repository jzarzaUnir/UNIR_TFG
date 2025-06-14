public class Cls_OrchestratorBatchSender implements Database.Batchable<Cls_OrchestratorQueueBatch.OrchestratorWrapper>, Database.AllowsCallouts {
	
	private List<Cls_OrchestratorQueueBatch.OrchestratorWrapper> listRequests;

	public Cls_OrchestratorBatchSender(List<Cls_OrchestratorQueueBatch.OrchestratorWrapper> listRequests) {
		this.listRequests = listRequests;
	}

	public Iterable<Cls_OrchestratorQueueBatch.OrchestratorWrapper>  start(Database.BatchableContext bc) {
		// No necesitamos una Query porque ya tenemos los datos en `listRequests`
		return this.listRequests;
	}

	public void execute(Database.BatchableContext bc, List<Cls_OrchestratorQueueBatch.OrchestratorWrapper> scope) {

		if (scope.isEmpty()) return;

		Cls_OrchestratorQueueBatch.OrchestratorWrapper itemRequest = (Cls_OrchestratorQueueBatch.OrchestratorWrapper) scope[0]; // Solo procesamos 1 JSON a la vez

		try {

			HttpResponse res = Cls_CJ_SFtoSFMC.sendRequest(itemRequest.endpoint, itemRequest.jsonPayload);

			if (res.getStatusCode() == 200 || res.getStatusCode() == 201)  {
				if (!itemRequest.listOrchestratorQueue.isEmpty()) {
					List<Orchestrator_Queue__c> updatedRecords = itemRequest.listOrchestratorQueue;
					for (Orchestrator_Queue__c record : updatedRecords) {
						record.Status__c = 'Processed';
					}
					Database.update(updatedRecords, false);
				}
			}

		} catch (Exception e) {
			Cls_ErrorHandler.insertError(
				e.getMessage(), 'ERR_APICALL', Cls_ErrorHandler.STR_ERROR_SALESFORCE, 
				e.getLineNumber(), 'Cls_OrchestratorBatchSender', 'execute.sendRequest', null
			);
		}
	}

	public void finish(Database.BatchableContext bc) {

	}
}