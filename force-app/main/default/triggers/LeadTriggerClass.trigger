trigger LeadTriggerClass on Lead (after insert, after update) {

    if(Trigger.isAfter && Trigger.isInsert){
        Cls_APIsOrchestrator orchestrator = new Cls_APIsOrchestrator(Trigger.new, 'Lead', true);
        orchestrator.executeOrchestrator();
    }

    if(Trigger.isAfter && Trigger.isUpdate){
        Cls_APIsOrchestrator orchestrator = new Cls_APIsOrchestrator(Trigger.new, 'Lead', false);
        orchestrator.executeOrchestrator();
    }
       
}