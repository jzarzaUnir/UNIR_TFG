@isTest
public class Cls_APIsOrchestratorTest {

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

        Test.startTest();
        Cls_APIsOrchestrator orchestrator = new Cls_APIsOrchestrator(records,'Task',true);
        orchestrator.executeOrchestrator();
        Test.stopTest();

        // Verificar los JSONs generados
        List<Orchestrator_Queue__c> orchestratorRecords = [SELECT Id FROM Orchestrator_Queue__c];
        Assert.isTrue(!orchestratorRecords.isEmpty());
    }
}