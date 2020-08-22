public class OpptyGates {

	public static Boolean passesClosedWonCriteria( Opportunity opp ) {
		
		String[] reqFields = new String[]{ 'Twilio_Team_involved__c',
										   'Referenceable_Customer__c',
										   'Quick_Company_Funding_Description__c',
										   'Lessons_Learned__c',
										   'How_we_won__c', 
										   'Deal_Details__c' };
										   
		for ( String fldName : reqFields ) {
			system.debug( fldName ); system.debug( String.isBlank( (String)opp.get( fldName ) ) );
			if ( String.isBlank( (String)opp.get( fldName ) ) )
				return false;
		}

		if ( opp.Closed_Won_Record_Type_Completed__c != true )
			return false;

		return true;
	}
	
	public static Boolean passedGatedPrior2ClosedWon( Opportunity opp ) {
		
		String[] reqFields = new String[]{ 'Validate_Solution_Completed__c',
											'Scope_Completed__c', 
											'Qualified_Completed__c',
											'MSA_Product_Launch_Stage_Completed__c',
											'Incubate_Completed__c',
											'Go_No_Go_Completed__c',
											'Business_Case_Completed__c' };
										   
		for ( String fldName : reqFields ) {
			
			if ( !(Boolean)opp.get( fldName ) )
				return false;
		}

		return true;		
	}

}