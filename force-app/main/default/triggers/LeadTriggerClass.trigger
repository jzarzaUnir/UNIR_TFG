trigger LeadTriggerClass on Lead (after insert) {


    Cls_APIsOrchestrator orchestrator = new Cls_APIsOrchestrator(Trigger.new, 'Lead', true);
    orchestrator.executeOrchestrator();
    
}