public with sharing class Cls_CalloutOrchestratorQueueable implements Queueable {
    public void execute( QueueableContext context ) {
        Database.executeBatch( new Cls_OrchestratorQueueBatch(), 50);
    }
}