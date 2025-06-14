@isTest
private class Cls_OrchestratorQueueBatchTest {
    
    @isTest
    static void testPolymorphicBatchExecution() {
        // Paso 1: Configurar los datos de prueba
        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'test@example.com', Phone = '111222333');
        Lead lead = new Lead(FirstName = 'Test', LastName = 'Lead', Company = 'Test Company', Email = 'test@test.com', Phone = '111222333');
        insert new List<SObject>{contact, lead};

        Task task1 = new Task(Subject = 'Task with Contact', WhoId = contact.Id);
        Task task2 = new Task(Subject = 'Task with Lead', WhoId = lead.Id);
        Task task3 = new Task(Subject = 'Task with null WhoId'); // No debería ser procesado
        insert new List<Task>{task1, task2, task3};

        // Paso 2: Crear la instancia del batch
        List<SObject> records = [SELECT Id, Subject, WhoId FROM Task WHERE WhoId != null];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Cls_APIsOrchestrator orchestrator = new Cls_APIsOrchestrator(records,'Task',true);
        orchestrator.executeOrchestrator();

        Test.startTest();
        Database.executeBatch( new Cls_OrchestratorQueueBatch(), 100);
        Test.stopTest();
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"requestId": "7c63213cggh-fffff-uuid-v3x1-bb7ui990", "count": 1, "notQueuedCount": 0, "members": [{"contactKey": "id1","eventInstanceId": "ccccc-444-1213-5555-ggggh8887876"}]}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    
    }

}