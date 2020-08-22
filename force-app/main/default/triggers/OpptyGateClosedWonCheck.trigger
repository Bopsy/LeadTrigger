trigger OpptyGateClosedWonCheck on Opportunity ( before insert, before update ) {

    /*for ( Opportunity opp : trigger.new ) {

        if ( OpptyGates.passedGatedPrior2ClosedWon( opp ) &&
             OpptyGates.passesClosedWonCriteria( opp ) &&
             opp.Closed_Won_Completed__c != true )
                opp.Closed_Won_Completed__c = true;

    }*/
}