/**********************************************************/
//Created by: Gram Bischof 8/22/2017
//Last Modified: Gram Bischof 8/22/2017
//
//Description: 
//This handles logic to be run when changes occur to 
//the Leads objects.
//
// Testing on changesets.io
/**********************************************************/
public class LeadTriggerHandler extends TriggerHandler {
    
    // new leads, new map, old map
    private final List<Lead> newLeads;
    private final Map<Id, Lead> newLeadsById;
    private final Map<Id, Lead> oldLeadsById;     
    
    // constructor
    public LeadTriggerHandler(List<sObject> newLeads, Map<Id, sObject> newLeadsById, Map<Id, sObject> oldLeadsById) {
        super();
        this.newLeads = (List<Lead>) newLeads;
        this.newLeadsById = (Map<Id, Lead>)newLeadsById;
        this.oldLeadsById = (Map<Id, Lead>)oldLeadsById;    
    }
    
    public override void executeBeforeInsert() {
        system.debug(LoggingLevel.ERROR, 'LEAD TRIGGER HANDLER BEFORE INSERT');   
    }
    
    public override void executeAfterInsert() {     
        system.debug(LoggingLevel.ERROR, 'LEAD TRIGGER HANDLER AFTER INSERT');   
    }
    
    public override void executeBeforeUpdate() {
        system.debug(LoggingLevel.ERROR, 'LEAD TRIGGER HANDLER BEFORE UPDATE');   
    }
    
    public override void executeAfterUpdate() {
        system.debug(LoggingLevel.ERROR, 'LEAD TRIGGER HANDLER AFTER UPDATE');   
    }
    
    public override void executeBeforeDelete() {
        system.debug(LoggingLevel.ERROR, 'LEAD TRIGGER HANDLER BEFORE DELETE');   
    }
    
    public override void executeAfterDelete() {
        system.debug(LoggingLevel.ERROR, 'LEAD TRIGGER HANDLER AFTER DELETE');   
    }
    
    public override void executeAfterUndelete() {
        system.debug(LoggingLevel.ERROR, 'LEAD TRIGGER HANDLER AFTER UNDELETE');   
    }    
}
