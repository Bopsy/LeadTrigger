public without sharing class ForecastSchedule {

    public static boolean forecastLineitemRecalc = false;

    //static Set<String> filteredStages = new Set<String>{'Go / No Go','Business Case','Contract/MSA/Launch','Production at Scale'};
    static Set<String> filteredForecastCateogries = new Set<String>{'BestCase', 'Pipeline', 'Closed', 'Commit'};

  private static final Set<String> IGNORED_FORECAST_CATEGORIES = new Set<String>{ 'Omitted' };
  private static final Set<String> IGNORED_PILOT_FORECAST_CATEGORIES = new Set<String>{ 'Omitted' };

//  public static Set<String> AVOID_OPP_RECTYPE_NAMES = new Set<String>{ 'Authy' };
    public static Set<String> AVOID_OPP_RECTYPE_NAMES = new Set<String>();

    private static Set<Id> oppRecTypeIds2Avoid;

    public static Set<Id> getOppRecTypeIds2Avoid() {

        if ( oppRecTypeIds2Avoid == NULL ) {

            oppRecTypeIds2Avoid = new Set<Id>();

            for ( RecordType rt : [ SELECT Id, Name FROM RecordType WHERE SObjectType = 'Opportunity' AND Name IN :AVOID_OPP_RECTYPE_NAMES ] )
                oppRecTypeIds2Avoid.add( rt.Id );
        }

        return oppRecTypeIds2Avoid;
    }

    private static Id forecastScheduleLockPBID {
        get {
            if( forecastScheduleLockPBID == NULL ) {
                Id standardPricebookId = Test.isRunningTest() ? Test.getStandardPricebookId() : [ SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE ].Id;
                forecastScheduleLockPBID = [ SELECT Id FROM PricebookEntry WHERE Product2.Name = 'Forecast Lock' AND Pricebook2Id = :standardPricebookId ].Id;
            }
            return forecastScheduleLockPBID;
        }
        private set;
    }

    public static Id getForecastScheduleLockPBID() {

        return forecastScheduleLockPBID;
    }

    public static void stampOppsForeSchedsAmount( List<Opportunity> newOpps ) {

        stampOppsForeSchedsAmount( newOpps, null );
    }

    public static void stampOppsForeSchedsAmount( List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps ) {

        String stageSought = 'Closed Won';

        List<Opportunity> opps4ForecastStamp = new List<Opportunity>();

        for ( Opportunity newOpp : newOpps ) {

            if ( oldOpps != null ) {

                Opportunity oldOpp = oldOpps.get( newOpp.Id );

                if ( oldOpp.StageName != stageSought && newOpp.StageName == stageSought )
                    opps4ForecastStamp.add( newOpp );

            } else {

                if ( newOpp.StageName == stageSought )
                    opps4ForecastStamp.add( newOpp );
            }
        }

        List<Forecast_Schedule__c> fscs = [ SELECT Forecast_Amount__c FROM Forecast_Schedule__c WHERE Opportunity__c IN :opps4ForecastStamp ];

        for ( Forecast_Schedule__c fs : fscs )
            fs.Forecasted_Amount_at_Close__c = fs.Forecast_Amount__c;

        if ( fscs.size() > 0 )
            update fscs;
    }

    public static void shiftOrCreateScheds( List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps ) {
        System.debug('Executing shiftOrCreateScheds()');
        
        List<Opportunity> filteredOpps = new List<Opportunity>();
        for(Opportunity opp: newOpps){
            Opportunity oldOpp = oldOpps.get(opp.Id);
            if(opp.Launch_Date__c != oldOpp.Launch_Date__c || opp.Amount != oldOpp.Amount || 
                opp.Pilot_Forecast_Category__c != oldOpp.Pilot_Forecast_Category__c || 
                opp.Pilot_Start_Date__c != oldOpp.Pilot_Start_Date__c || opp.Pilot_End_Date__c != oldOpp.Pilot_End_Date__c ||
                opp.Contract_Terms_Months__c != oldOpp.Contract_Terms_Months__c || opp.StageName != oldOpp.StageName){
                filteredOpps.add(opp);
            }
        }
        // Create a map of the newOpps for convenience
        if(filteredOpps.isEmpty()) return;
        Map<Id,Opportunity> newOppsMap = new Map<Id,Opportunity>();
        for (Opportunity o : filteredOpps) { newOppsMap.put(o.Id, o); }

        Map<Id,List<Forecast_Schedule__c>> oppsWPilotForeScheds = new Map<Id,List<Forecast_Schedule__c>>();
        Map<Id,List<Forecast_Schedule__c>> oppsWForeScheds = new Map<Id,List<Forecast_Schedule__c>>();
        for( Forecast_Schedule__c fs : [
            SELECT Opportunity__c, Start_Date__c, End_Date__c, Forecast_Schedule_Type__c, Forecast_Amount__c, Is_Pilot__c
            FROM Forecast_Schedule__c
            WHERE Opportunity__c IN :filteredOpps
            ORDER BY End_Date__c ASC
        ] ) {
            System.debug(fs);

            Id oppId = (Id)fs.get('Opportunity__c');

            // Maintain separate list for forecast schedules based on it being a pilot or not
            //if (fs.Forecast_Schedule_Type__c == 'Pilot') {
            if (fs.Is_Pilot__c) {
                //Opportunity opp = newOppsMap.get(oppId);
                //Opportunity oldOpp = oldOpps.get(oppId);

                // Proceed if the Pilot_Forecast_Catergory is set and not equal to 'Omitted'
                //if (String.isNotBlank(opp.Pilot_Forecast_Category__c) && !IGNORED_PILOT_FORECAST_CATEGORIES.contains(opp.Pilot_Forecast_Category__c)) {

                    // Proceed if the Pilot_Start_Date__c and Pilot_End_Date__c are set
                 //   if (opp.Pilot_Start_Date__c != null && opp.Pilot_End_Date__c != null) {
                        // Initialized the Forecast_Scheduled__c sublist if it hasn't been yet
                 //       if ( !oppsWPilotForeScheds.containsKey( oppId ) ) oppsWPilotForeScheds.put( oppId, new List<Forecast_Schedule__c>() );  
                 //       oppsWPilotForeScheds.get( oppId ).add( fs );
                 //   }
                //}
            } else {
                if ( !oppsWForeScheds.containsKey( oppId ) ) oppsWForeScheds.put( oppId, new List<Forecast_Schedule__c>() );                
                oppsWForeScheds.get( oppId ).add( fs );
            }
        }

        System.debug('oppsWForeScheds count: ' + oppsWForeScheds.size());
        System.debug('oppsWPilotForeScheds count: ' + oppsWPilotForeScheds.size());

        List<Opportunity> opps4ForeSchedShift = new List<Opportunity>();
        List<Opportunity> editOpps4NewForeScheds = new List<Opportunity>();
        Map<Id,List<Forecast_Schedule__c>> oppsWContactTermsChange = new Map<Id,List<Forecast_Schedule__c>>();

        for ( Opportunity newOpp : filteredOpps ) {

            Opportunity oldOpp = oldOpps.get( newOpp.Id );

            // If the Opportunity Launch Date changes shift the Forecast Scheduled dates accordingly
            if ( newOpp.Launch_Date__c != oldOpp.Launch_Date__c && newOpp.Launch_Date__c != null ) {
                opps4ForeSchedShift.add( newOpp );

            // If the Opportunity has an Amount and Launch Date, but does not have any Forecast Schedule records then process it for creating them
//          } else if ( newOpp.Amount != 0 && newOpp.Launch_Date__c != null && (!oppsWForeScheds.containsKey(newOpp.Id) || !oppsWPilotForeScheds.containsKey(newOpp.Id))) {
            } else if ( newOpp.Amount != 0 && newOpp.Launch_Date__c != null && !oppsWForeScheds.containsKey(newOpp.Id)) {
                editOpps4NewForeScheds.add( newOpp );
            }

/*
            // If the Opportunity has any Forecast Schedule records and the Contract Terms have been changed then process
            // it by adding or deleting Forecast Schedule records as needed
            if (oppsWForeScheds.containsKey(newOpp.Id) && newOpp.Contract_Terms_Months__c != 0 && newOpp.Contract_Terms_Months__c != oldOpp.Contract_Terms_Months__c)
                oppsWContactTermsChange.put( newOpp.Id, oppsWForeScheds.get( newOpp.Id ));
*/
        }

        System.debug('opps4ForeSchedShift count: ' + opps4ForeSchedShift.size());
        System.debug('editOpps4NewForeScheds count: ' + editOpps4NewForeScheds.size());

        if ( !editOpps4NewForeScheds.isEmpty() )
            filterAndCreateForecasts( editOpps4NewForeScheds, oldOpps );
        
        if(opps4ForeSchedShift.isEmpty() && editOpps4NewForeScheds.isEmpty()) return;
        List<Forecast_Schedule__c> fs4Shift = new List<Forecast_Schedule__c>();
        List<Forecast_Schedule__c> fs4Delete = new List<Forecast_Schedule__c>();

        for( Opportunity opp4SchedShift : opps4ForeSchedShift ) {

            if ( !oppsWForeScheds.containsKey( opp4SchedShift.Id ) || ForecastSchedule.getOppRecTypeIds2Avoid().contains( opp4SchedShift.RecordTypeId ) )
                continue;

            List<Forecast_Schedule__c> theScheds = oppsWForeScheds.get( opp4SchedShift.Id );

            Integer shiftCount = opp4SchedShift.Contract_Terms_Months__c < theScheds.size() ? (Integer)opp4SchedShift.Contract_Terms_Months__c : theScheds.size();

            for(Integer i = 0; i < shiftCount; i++){
                Forecast_Schedule__c forecastSchedule = theScheds[ i ];
                Date startDate = opp4SchedShift.Launch_Date__c.addMonths(i).toStartOfMonth();
                Date endDate = startDate.addMonths(1).toStartOfMonth().addDays(-1);
                forecastSchedule.Start_Date__c = startDate;
                forecastSchedule.End_Date__c = endDate;
                fs4Shift.add(forecastSchedule);
            }
        }

/*
        // Process Forecast Schedule records where the Opportunity Contract Terms changed
        if ( !oppsWContactTermsChange.isEmpty() ) {
            ForecastScheduleReturnValue retVal = updateForecastSchedulesForContractTerms( newOppsMap, oldOpps, oppsWContactTermsChange );
            fs4Shift.addAll(retVal.recordsToAdd);
            fs4Delete.addAll(retVal.recordsToDelete);
        }
*/

        // Process the Pilot Forecast Schedule records
        //ForecastScheduleReturnValue retVal = updatePilotForecastSchedules(newOppsMap, oldOpps, oppsWPilotForeScheds);
        //fs4Shift.addAll(retVal.recordsToAdd);
        //fs4Delete.addAll(retVal.recordsToDelete);
        
        if ( !fs4Delete.isEmpty() )
            delete fs4Delete;
            
        if ( !fs4Shift.isEmpty() )
            upsert fs4Shift;
    }


    //
    // This is check used to ensure that if the trigger is called recursively it will only be ran once.
    // Use it by specifying a "key" for the code segment it is being used for.  Each code segment should
    // have its own unique key.  For instance,
    //
    //    if (runOnce('For Forecast Schedule')) {
    //       ...
    //    }
    //
    //    if (runOnce('For Pilot Forecast Schedule')) {
    //       ...
    //    }
    //
    private static Set<String> run = new Set<String>();
    public static boolean runOnce(String key) { if (run.contains(key)) { return false; } else { run.add(key); return true; } }

    public class ForecastScheduleReturnValue {
        public List<Forecast_Schedule__c> recordsToAdd;
        public List<Forecast_Schedule__c> recordsToDelete;
        
        public ForecastScheduleReturnValue() {
            recordsToAdd = new List<Forecast_Schedule__c>();
            recordsToDelete = new List<Forecast_Schedule__c>();
        }
    }

/*  DISABLED BECAUSE OF UNEXPECTED BEHAVIOR - MORE DESIGN WORK NEEDS TO BE DONE

 *  Dynamically adding/removing Forecast Schedules when the Opportunity.Contact_Terms_Months__c is changed).
 *  The reason for this is the situation where a user manually deletes a Forecast Schedule record.
 *  When the record is deleted the Opportunity.Contract_Terms_Months__c is still the original value so when
 *  the code findOrCreateSched() executes a new Forecast Schedule created to ensure that the Contract Terms
 *  Months has that many Forecast Schedule records.

    //
    // Manages the creation/deletion of additional Forecast Schedule records when the Contract Terms are changed
    // If there are existing Forecast Scheduled record and the Contract Terms change create or delete records as needed.
    // If new records are created the amount on the last existing record it used as the value on all newly created records.
    //
    public static ForecastScheduleReturnValue updateForecastSchedulesForContractTerms(Map<Id,Opportunity> newOpps, Map<Id,Opportunity> oldOpps, Map<Id,List<Forecast_Schedule__c>> oppsWContactTermsChange) {
        ForecastScheduleReturnValue retVal = new ForecastScheduleReturnValue();
        
        if (runOnce('For updateForecastSchedulesForContractTerms')) {
            // Process the Opportunities with Contract Terms changed
            System.debug('Check to see if the opportunities should have pilot forecast records but do not');
            for ( Id oppId : oppsWContactTermsChange.keySet() ) {
                Opportunity newOpp = newOpps.get(oppId);
                Opportunity oldOpp = oldOpps.get(oppId);
                List<Forecast_Schedule__c> fsList = oppsWContactTermsChange.get(oppId);
                
                // If Contract Terms was increased create new Forecast Schedule records using the Amount on the
                // last existing Forecast Schedule record as the Amount for the new ones
                System.debug('If Contract Terms was increased create new Forecast Schedule records using the Amount on the last existing Forecast Schedule record as the Amount for the new ones');
                System.debug('If Contract Terms was decreased delete Forecast Schedule records outsite of the terms');
                System.debug('Contract_Terms__c = ' + newOpp.Contract_Terms_Months__c + ' (Old value = ' + oldOpp.Contract_Terms_Months__c + ', Current Forecast Schedule Total = ' + fsList.size() + ')');
                if (newOpp.Contract_Terms_Months__c != null &&  newOpp.Contract_Terms_Months__c > oldOpp.Contract_Terms_Months__c) {
                    // Get the last existing Forecast Schedule record
                    Forecast_Schedule__c lastFS = fsList[oppsWContactTermsChange.size() - 1];

                    System.debug('Creating new forecast schedule records');
                    for(Integer i = fsList.size(); i < newOpp.Contract_Terms_Months__c; i++) {
                        Date currentMonth = lastFS.Start_Date__c.addMonths(i).toStartOfMonth();
                        System.debug('Creating forecast schedule for ' + currentMonth + ')');
                        retVal.recordsToAdd.add(new Forecast_Schedule__c(
                            Opportunity__c = oppId,
                            Start_Date__c = currentMonth,
                            End_Date__c = currentMonth.addMonths(1).toStartOfMonth().addDays(-1),
                            Forecast_Amount__c = lastFS.Forecast_Amount__c,
                            Is_Pilot__c = false
                        ));
                    }

                // If Contract Terms was increased create new Forecast Schedule records using the Amount on the
                // last existing Forecast Schedule record as the Amount for the new ones
                } else if (newOpp.Contract_Terms_Months__c != null && newOpp.Contract_Terms_Months__c < oldOpp.Contract_Terms_Months__c && newOpp.Contract_Terms_Months__c <= fsList.size()) {
                    System.debug('Deleting forecast schedule records outside of terms (Record Indices ' + newOpp.Contract_Terms_Months__c + ' to ' + fsList.size() + ')');
                    for(Integer i = Integer.valueOf(newOpp.Contract_Terms_Months__c); i < fsList.size(); i++) {
                        // Do not delete any Pilot Forecast Schedules
                        if (!fsList[i].Is_Pilot__c) {
                            retVal.recordsToDelete.add(fsList[i]);
                        }
                    }
                }
            }
        }
        return retval;
    }
*/
    
    //
    // Manages the creation/deletion of Pilot Forecast Schedule records 
    // Uses Pilot Start Date, Pilot End Date, Pilot Forecast Catetory to determine which forecast schedules should be created or deleted
    //
    /*public static ForecastScheduleReturnValue updatePilotForecastSchedules(Map<Id,Opportunity> newOpps, Map<Id,Opportunity> oldOpps, Map<Id,List<Forecast_Schedule__c>> oppsWPilotForeScheds) {
        ForecastScheduleReturnValue retVal = new ForecastScheduleReturnValue();
        
//      if (runOnce('For updatePilotForecastSchedules')) {
            // Check to see if the opportunities should have pilot forecast records but do not
            System.debug('Check to see if the opportunities should have pilot forecast records but do not');
            for ( Opportunity opp : newOpps.values() ) {
                Opportunity oldOpp = oldOpps.get(opp.Id);
                
                // If pilot info is present and no pilot forecast schedule records exist, create them
                System.debug('If pilot info is present and no pilot forecast schedule records exist, create them');
                System.debug('Not in oppsWPilotForeScheds = ' + (!oppsWPilotForeScheds.containsKey(opp.Id) ? 'yes' : 'no'));
                System.debug('Pilot_Start_Date__c = ' + opp.Pilot_Start_Date__c + ' (Old value = ' + oldOpp.Pilot_Start_Date__c + ')');
                System.debug('Pilot_End_Date__c = ' + opp.Pilot_End_Date__c + ' (Old value = ' + oldOpp.Pilot_End_Date__c + ')');
                System.debug('Pilot_Forecast_Category__c = ' + opp.Pilot_Forecast_Category__c);
                if (
                    !oppsWPilotForeScheds.containsKey(opp.Id) &&
                    opp.Pilot_Start_Date__c != null &&
                    opp.Pilot_End_Date__c != null &&
                    String.isNotBlank(opp.Pilot_Forecast_Category__c) &&
                    !IGNORED_PILOT_FORECAST_CATEGORIES.contains(opp.Pilot_Forecast_Category__c)
                ) {
                    Date startMonth = opp.Pilot_Start_Date__c.toStartOfMonth();
                    Date endMonth = opp.Pilot_End_Date__c.toStartOfMonth();
    
                    System.debug('Creating pilot forecast schedule records');
                    for(Date currentMonth = startMonth; currentMonth <= endMonth; currentMonth = currentMonth.addMonths(1)) {
                        System.debug('Creating pilot forecast schedule for ' + currentMonth + ')');
                        retVal.recordsToAdd.add(new Forecast_Schedule__c(
                            Opportunity__c = opp.Id,
                            Start_Date__c = currentMonth,
                            End_Date__c = currentMonth.addMonths(1).toStartOfMonth().addDays(-1),
                            Forecast_Amount__c = 0,
                            Is_Pilot__c = true
                        ));
                    }
                }
            }
    
            // Process the Pilot Forecast Schedule records that need to be updated
            for (Id oppId : oppsWPilotForeScheds.keySet()) {
                Opportunity opp4SchedShift = newOpps.get(oppId);
                System.debug('Reviewing opportunity ' + oppId);
                
                if ( !oppsWPilotForeScheds.containsKey( opp4SchedShift.Id ) || ForecastSchedule.getOppRecTypeIds2Avoid().contains( opp4SchedShift.RecordTypeId ) )
                    continue;
    
                System.debug('Processing opportunity ' + oppId);
    
                List<Forecast_Schedule__c> theScheds = oppsWPilotForeScheds.get( opp4SchedShift.Id );
                Integer numOfRecs = theScheds.size();
    
                Date startMonth = opp4SchedShift.Pilot_Start_Date__c.toStartOfMonth();
                Date endMonth = opp4SchedShift.Pilot_End_Date__c.toStartOfMonth();
                Integer i = 0;
    
                // If the Pilot Start Date was moved up, delete all forecast schedule records before it
                System.debug('If the Pilot Start Date was delayed, delete all forecast schedule records before it');
                while (startMonth > theScheds[i].Start_Date__c) {
                    System.debug('Deleting pilot forecast schedule: ' + theScheds[i].Id + ' (' + startMonth + ' < ' + theScheds[i].Start_Date__c + ')');
                    retVal.recordsToDelete.add(theScheds[i++]);
                }
                
                // If there is no forecast schedule record with that start date, create it
                System.debug('If there is no pilot forecast schedule record with that start date, create it');
                for(Date currentMonth = startMonth; currentMonth <= endMonth; currentMonth = currentMonth.addMonths(1)) {
                    System.debug('i >= numOfRecs (' + i + ' >= ' + numOfRecs + ')');
                    if (i < numOfRecs) System.debug('currentMonth != theScheds[i].Start_Date__c (' + currentMonth + ' >= ' + theScheds[i].Start_Date__c + ')');
                    
                    // If the current month already has an forecast schedule record for that month then don't create a new record
                    if (i < numOfRecs && currentMonth == theScheds[i].Start_Date__c) {
                        System.debug('Existing pilot forecast schedule for ' + currentMonth + ')');
                        i++;
                        continue;
                    }
                    
                    if (i >= numOfRecs || currentMonth != theScheds[i].Start_Date__c) {
                        System.debug('Creating pilot forecast schedule for ' + currentMonth + ')');
                        retVal.recordsToAdd.add(new Forecast_Schedule__c(
                            Opportunity__c = oppId,
                            Start_Date__c = currentMonth,
                            End_Date__c = currentMonth.addMonths(1).toStartOfMonth().addDays(-1),
                            Forecast_Amount__c = 0,
                            Is_Pilot__c = true
                        ));
                    }
                }
                
                // If the Pilot End Date was moved up, delete all forecast schedule records after that
                System.debug('If the Pilot End Date was moved up, delete all forecast schedule records after that');
                while (i < numOfRecs) {
                    System.debug('Deleting forecast schedule: ' + theScheds[i].Id + ' (' + endMonth + ' > ' + theScheds[i].Start_Date__c + ')');
                    retVal.recordsToDelete.add(theScheds[i++]);
                }
            }
//      }
        return retval;
    }*/
    @future
    public static void adjustAmountViaSchedsfuture(Set<Id> forecastIds){
        List<Forecast_Schedule__c> forecasts = [SELECT Id, Forecast_Amount__c, Start_Date__c, Opportunity__c, Is_Pilot__c FROM Forecast_Schedule__c WHERE Id=:forecastIds];
        adjustAmountViaScheds(true, false, false, forecasts, new Map<Id, Forecast_Schedule__c>());
    }
    
    public static void adjustAmountViaScheds( Boolean isInsert, Boolean isUpdate, Boolean isDelete, List<Forecast_Schedule__c> newForeSchedsIncoming, Map<Id, Forecast_Schedule__c> oldForeSchedsIncoming ) {
        System.debug('Starting - ForecastSchedule.adjustAmountViaScheds()');
        
        Map<Id, OpportunityLineItem> oppId2OppLineItems = new Map<Id, OpportunityLineItem>();

        // Only work on non-Pilot Forecast Schedules
        List<Forecast_Schedule__c> newForeScheds = new List<Forecast_Schedule__c>();
        if (newForeSchedsIncoming != null) {
            for (Forecast_Schedule__c fs : newForeSchedsIncoming) {
                if (!fs.Is_Pilot__c)
                    newForeScheds.add(fs);
            }
        }

        Map<Id, Forecast_Schedule__c> oldForeScheds = new Map<Id, Forecast_Schedule__c>();
        if (oldForeSchedsIncoming != null) {
            for (Forecast_Schedule__c fs : oldForeSchedsIncoming.values()) {
                if (!fs.Is_Pilot__c)
                    oldForeScheds.put(fs.Id, fs);
            }
        }

        Set<Id> oppIds = new Set<Id>();
//      Set<Id> oppHasNonPilotForecastSchedule = new Set<Id>();

        if ( isInsert || isUpdate ) {
    
            // Only adjust amounts for Opportunities that have at least 1 non-pilot forecast schedule
            for ( Forecast_Schedule__c fs : newForeScheds ) {
                System.debug('Checking Opportunity for processing: ' + fs.Opportunity__c + ' [Forecast_Schedule__c (Id=' + fs.Id + ', Start_Date__c=' + fs.Start_Date__c + ', Is_Pilot__c=' + fs.Is_Pilot__c + ')]');
                if (!fs.Is_Pilot__c) {
                    System.debug('Adding Opportunity for processing: ' + fs.Opportunity__c);
//                    oppHasNonPilotForecastSchedule.add( fs.Opportunity__c );
                    oppIds.add( fs.Opportunity__c );
                }
            }

        } else if ( isDelete ) {

            for ( Forecast_Schedule__c oldFs : oldForeScheds.values() )
                oppIds.add( oldFs.Opportunity__c );
        }

        // If update, must retrieve pre-existing & map by Opp Id
        List<OpportunityLineItem> oppLineItems = [ SELECT Id, OpportunityId, Opportunity.StageName, TotalPrice FROM OpportunityLineItem WHERE OpportunityId IN :oppIds ];

        for ( OpportunityLineItem oli : oppLineItems )
            oppId2OppLineItems.put( oli.OpportunityId, oli );

        List<Forecast_Schedule__c> scheds2Process;

        if ( isUpdate ) {

            scheds2Process = new List<Forecast_Schedule__c>();

            for ( Forecast_Schedule__c newForecast : newForeScheds ) {

                Forecast_Schedule__c oldForecast = oldForeScheds.get( newForecast.Id );

                // Only reprocess if the Opportunity has at least 1 non Pilot Forecast Schedule and the Forecast Amount has changed
//              if ( oppHasNonPilotForecastSchedule.contains(newForecast.Opportunity__c) && newForecast.Forecast_Amount__c != oldForecast.Forecast_Amount__c ) {
                if ( newForecast.Forecast_Amount__c != oldForecast.Forecast_Amount__c ) {
                    System.debug('Adding Opportunity for scheds2Process: ' + newForecast.Opportunity__c);
                    scheds2Process.add( newForecast );
                }
            }

        } else if ( isInsert ){

            scheds2Process = newForeScheds;

        } else if ( isDelete ) {

            scheds2Process = oldForeScheds.values();
        }

        Set<Id> oppIdsForReprocess = new Set<Id>();

        for ( Forecast_Schedule__c fs : scheds2Process )
            oppIdsForReprocess.add( fs.Opportunity__c );

        for ( Id i : oppIdsForReprocess )
            System.debug('Opportunity to reprocess: ' + i);

        List<Forecast_Schedule__c> allExistingForecasts = [
            SELECT Id, Forecast_Amount__c, Opportunity__c, Is_Pilot__c
            FROM Forecast_Schedule__c
            WHERE Opportunity__c IN :oppIdsForReprocess
            AND Is_Pilot__c = false
        ];

        Map<Id, decimal> oppId2ForecastSum = new Map<Id, decimal>();
        Map<Id, integer> oppId2ForecastCnt = new Map<Id, integer>();

        for ( Forecast_Schedule__c fs2Agg : allExistingForecasts ) {

            if ( !oppId2ForecastSum.containsKey( fs2Agg.Opportunity__c ) )
                oppId2ForecastSum.put( fs2Agg.Opportunity__c, 0 );

            if ( !oppId2ForecastCnt.containsKey( fs2Agg.Opportunity__c ) )
                oppId2ForecastCnt.put( fs2Agg.Opportunity__c, 0 );

            // Do not include pilot forecasts in the count
            decimal fsAgg = oppId2ForecastSum.get( fs2Agg.Opportunity__c );
            fsAgg += fs2Agg.Forecast_Amount__c;
            oppId2ForecastSum.put( fs2Agg.Opportunity__c, fsAgg );

            integer fsCnt = oppId2ForecastCnt.get( fs2Agg.Opportunity__c );
            System.debug('Updating Opportunity(' + fs2Agg.Opportunity__c + ') Old Amount(' + fs2Agg.Forecast_Amount__c + ') Old Contract_Terms(' + fsCnt + ')');
            fsCnt++;
            oppId2ForecastCnt.put( fs2Agg.Opportunity__c, fsCnt );
                
            System.debug('Updating Opportunity(' + fs2Agg.Opportunity__c + ') New Amount(' + fsAgg + ') New Contract_Terms(' + fsCnt + ')');
        }

        List<OpportunityLineItem> oppLineItems4DML = new List<OpportunityLineItem>();
        List<Opportunity> opps4DML = new List<Opportunity>();

        Map<Id, Opportunity> id2Opp = new Map<Id, Opportunity>( [ SELECT Id, StageName, ForecastCategory FROM Opportunity WHERE Id IN :oppIdsForReprocess ] );

        for ( Id oppId4Reproc : oppIdsForReprocess ) {
            System.debug('Reprocessing Opportunity: ' + oppId4Reproc);

            // Skip if the Opportunity has either:
            //   - StageName of "Closed Won
            //   - ForecastCategory not ignored
            //   - Only Pilot Forecast Schedules
//          if ( id2Opp.get( oppId4Reproc ).StageName == 'Closed Won' || IGNORED_FORECAST_CATEGORIES.contains( id2Opp.get( oppId4Reproc ).ForecastCategory ) )
            if ( id2Opp.get( oppId4Reproc ).StageName == 'Closed Won' )
                continue;

            System.debug('Setting Contact_Terms_Months__c('+ oppId2ForecastCnt.get( oppId4Reproc ) + ')');
            opps4DML.add( new Opportunity( Id = oppId4Reproc, Contract_Terms_Months__c = oppId2ForecastCnt.get( oppId4Reproc ) ) );

            Decimal totalPrice = oppId2ForecastSum.containsKey( oppId4Reproc ) ? oppId2ForecastSum.get( oppId4Reproc ) : 0.0;

            if ( !oppId2OppLineItems.containsKey( oppId4Reproc ) ) {
                System.debug('Adding Opportunity Line Item Forecast Lock for: ' + oppId4Reproc);
                oppLineItems4DML.add( new OpportunityLineItem( Quantity = 1, PricebookEntryId = getForecastScheduleLockPBID(), TotalPrice = totalPrice, OpportunityId = oppId4Reproc ) );

            } else {

                OpportunityLineItem existingLI = oppId2OppLineItems.get( oppId4Reproc );
                System.debug('May Update Opportunity Line Item Forecast Lock: '+ existingLI.Id + ')');

                if ( existingLI.Opportunity.StageName == 'Closed Won' )
                    continue;

                System.debug('Updating Opportunity Line Item(' + existingLI.Id + ') Old TotalPrice(' + existingLI.TotalPrice + ')');
                existingLI.TotalPrice = totalPrice;
                oppLineItems4DML.add( existingLI );
                System.debug('Updating Opportunity Line Item(' + existingLI.Id + ') New TotalPrice(' + existingLI.TotalPrice + ')');
            }
        }

        if ( oppLineItems4DML.size() > 0 ){
            if(!Test.isRunningTest()){
                upsert oppLineItems4DML;
            }
        }

        if ( opps4DML.size() > 0 )
            upsert opps4DML;

    }

    public static void filterAndCreateForecasts(List<Opportunity> opportunities, Map<Id, Opportunity> oldOpportunities){
        List<Opportunity> filteredOpportunities = new List<Opportunity>();
        Set<Id> filteredOpportunityIds = new Set<Id>();
        for(Opportunity opportunity : opportunities){
            Opportunity oldOpportunity = oldOpportunities.get(opportunity.Id);

            system.debug( ForecastSchedule.getOppRecTypeIds2Avoid() );
            system.debug( opportunity.RecordTypeId );

            //only want opportunties where terms or other data changes
            if( !ForecastSchedule.getOppRecTypeIds2Avoid().contains( opportunity.RecordTypeId ) &&
                (opportunity.Amount > 0 && opportunity.Amount != oldOpportunity.Amount)
                || (opportunity.Contract_Terms_Months__c != null && opportunity.Contract_Terms_Months__c != oldOpportunity.Contract_Terms_Months__c)
                || (opportunity.Launch_Date__c != null && opportunity.Launch_Date__c != oldOpportunity.Launch_Date__c)
                || (filteredForecastCateogries.contains(opportunity.ForecastCategory) && opportunity.StageName != oldOpportunity.StageName)
                ) {
                filteredOpportunities.add(opportunity);
                filteredOpportunityIds.add(opportunity.Id);
            }
        }

        if(!filteredOpportunities.isEmpty()){
            // Exclude Pilot Forecast Schedules
            List<Forecast_Schedule__c> oldForecastSchedules = [
                SELECT Id
                FROM Forecast_Schedule__c
                WHERE Opportunity__c in :filteredOpportunityIds
                AND Is_Pilot__c = false
            ];
            delete oldForecastSchedules;
            createForecasts(filteredOpportunities);
        }
    }

    public static void createForecasts(List<Opportunity> opportunities){
        List<Forecast_Schedule__c> forecastSchedules = new List<Forecast_Schedule__c>();
        for(Opportunity opportunity : opportunities){
            Boolean isForecastable = opportunity.Amount > 0 && opportunity.Contract_Terms_Months__c != null && filteredForecastCateogries.contains(opportunity.ForecastCategory) && !ForecastSchedule.getOppRecTypeIds2Avoid().contains( opportunity.RecordTypeId );
            if(isForecastable) {
                Decimal termMonths = opportunity.Contract_Terms_Months__c;
                Decimal averageAmount = opportunity.Amount / termMonths;
                for(Integer i = 0; i < termMonths; i++){
                    Forecast_Schedule__c forecastSchedule = new Forecast_Schedule__c(Opportunity__c=opportunity.Id);
                    Date startDate = opportunity.Launch_Date__c.addMonths(i).toStartOfMonth();
                    Date endDate = startDate.addMonths(1).toStartOfMonth().addDays(-1);
                    forecastSchedule.Start_Date__c = startDate;
                    forecastSchedule.End_Date__c = endDate;
                    forecastSchedule.Forecast_Amount__c = averageAmount;
                    forecastSchedules.add(forecastSchedule);
                }
            }
        }

        if(!forecastSchedules.isEmpty()){
            insert forecastSchedules;
        }
        List<Opportunity_Product__c> products = [SELECT Opportunity__c FROM Opportunity_Product__c WHERE Opportunity__c =: opportunities];
        Map<Id, Id> oppProductMap = new Map<Id, Id>();
        List<Product_Schedule__c> insertProdSchedules = new List<Product_Schedule__c>();
        for(Opportunity_Product__c prod: products){
            oppProductMap.put(prod.Opportunity__c, prod.Id);
        }
        
        for(Forecast_Schedule__c sch: forecastSchedules){
            Product_Schedule__c prodSchedules = new Product_Schedule__c(Forecast_Schedule__c = sch.Id);
            Id prodId = oppProductMap.get(sch.Opportunity__c);
            if(prodId != null){
                prodSchedules.Opportunity_Product__c = prodId;
                prodSchedules.Start_Date__c = sch.Start_Date__c;
                prodSchedules.End_Date__c = sch.End_Date__c;
                prodSchedules.New_Business_Forecast_Amount__c = sch.Forecast_Amount__c;
                insertProdSchedules.add(prodSchedules);
            }
        }
        
        if(!insertProdSchedules.isEmpty()){
            insert insertProdSchedules;
        }
    }

}