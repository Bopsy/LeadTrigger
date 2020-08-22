trigger UseCaseAfterTrigger on Use_Case__c (after insert, after update) {
    if (Trigger.isInsert) {
        // Call To Action Processing
        CallToActionHandler.setStatus(Trigger.newMap);
    }
}