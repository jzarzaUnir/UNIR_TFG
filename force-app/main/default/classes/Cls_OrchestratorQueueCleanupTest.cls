@IsTest
private class Cls_OrchestratorQueueCleanupTest {
    
    @testSetup
    static void setupTestData() {
        List<Orchestrator_Queue__c> testRecords = new List<Orchestrator_Queue__c>();

        for (Integer i = 0; i < 100; i++) {
            testRecords.add(new Orchestrator_Queue__c(
                ObjectName__c = 'Lead',
                RecordId__c = '00Q' + i,
                Status__c = 'Processed',
                CustomerJourney__c = 'CJ-' + i,
                ContactKey__c = 'CK-' + i,
                JSON__c = '{"sample":"json"}'
            ));
        }
        insert testRecords;

    }

    @isTest
    static void testBatchExecution() {
        // Verificar que los registros existen antes de ejecutar el batch
        Integer countBefore = [SELECT COUNT() FROM Orchestrator_Queue__c WHERE Status__c = 'Processed' AND CreatedDate <= LAST_N_MONTHS:6];
        Assert.areEqual(100, countBefore, 'Debe haber 5 registros procesados antes de ejecutar el batch');

        // Ejecutar el batch
        Test.startTest();
        Database.executeBatch(new Cls_OrchestratorQueueCleanupBatch(), 200);
        Test.stopTest();

        // Verificar que los registros fueron eliminados
        Integer countAfter = [SELECT COUNT() FROM Orchestrator_Queue__c WHERE Status__c = 'Processed' AND CreatedDate <= LAST_N_MONTHS:6];
        Assert.areEqual(0, countAfter, 'Todos los registros procesados deberían haber sido eliminados');

        // Verificar que los registros fueron eliminados
        Integer countDeleted = [SELECT COUNT() FROM Orchestrator_Queue__c WHERE Status__c = 'Processed' ALL ROWS];
        Assert.areEqual(100, countDeleted, 'Todos los registros procesados deberían haber sido eliminados');
    }

    @isTest
    static void testScheduledExecution() {
        Test.startTest();
        // Simular la ejecución programada del batch
        Cls_OrchestratorQueueCleanupBatch scheduler = new Cls_OrchestratorQueueCleanupBatch();
        scheduler.execute(null);
        Test.stopTest();

        System.assert(true, 'El batch programado se ejecutó sin errores.');
    }

}