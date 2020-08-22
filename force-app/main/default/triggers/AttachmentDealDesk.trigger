trigger AttachmentDealDesk on Attachment ( before insert ) {
	
	Set<Id> attachmentParents = new Set<Id>();
	
	for ( Attachment attc : Trigger.new )
		attachmentParents.add( attc.ParentId );
	
    List<Deal_Desk_Request__c> parentDealDesks = [ SELECT id, Quote_Pricing_Sheet_Attached__c 
    											   FROM Deal_Desk_Request__c WHERE id IN :attachmentParents ];
    
    if ( parentDealDesks.size() > 0 ) {
    	
    	for ( Deal_Desk_Request__c dealDesk : parentDealDesks )
        	dealDesk.Quote_Pricing_Sheet_Attached__c = true;
    	
    	update parentDealDesks;
	}
	
}