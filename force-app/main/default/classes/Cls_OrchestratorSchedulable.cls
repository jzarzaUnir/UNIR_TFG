public with sharing class Cls_OrchestratorSchedulable implements Schedulable {
    public void execute(SchedulableContext context){
        Database.executeBatch(new Cls_OrchestratorQueueBatch(),50);
    }
}