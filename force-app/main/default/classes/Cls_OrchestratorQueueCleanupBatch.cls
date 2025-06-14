global class Cls_OrchestratorQueueCleanupBatch implements Database.Batchable<SObject>, Schedulable {

	global Iterable<SObject> start(Database.BatchableContext bc) {

		List<SObject> listToDelete =  [SELECT Id FROM Orchestrator_Queue__c WHERE Status__c = 'Processed' AND CreatedDate < LAST_N_MONTHS:6];
		return listToDelete;
	}

	global void execute(Database.BatchableContext bc, List<SObject> scope) {
		if(!scope.isEmpty()) {
			Database.delete(scope,false);
		} // Elimina registros en lotes de 200
	}

	global void finish(Database.BatchableContext bc) {
		System.debug('Batch de limpieza de Orchestrator_Queue finalizado correctamente.');
	}

	global void execute(SchedulableContext sc) {
		Database.executeBatch(new Cls_OrchestratorQueueCleanupBatch(), 200);
	}
}



/// PARA EJECUTARLO CADA 6 MESES

//String jobName = 'OrchestratorQueueCleanup_Schedule';
//String cronExp = '0 0 0 1 */6 ? *'; // Cada 6 meses, el día 1 a medianoche
//System.schedule(jobName, cronExp, new Cls_OrchestratorQueueCleanupBatch());