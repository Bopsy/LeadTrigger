public class FieldSalesForecast {
    
    private static final Set<String> IGNORED_FORECAST_CATEGORIES = new Set<String>{};
        private static final Set<String> IGNORED_PILOT_FORECAST_CATEGORIES = new Set<String>{};
            
            public static Boolean disableFuture = false;
    
    //
    // This is check used to ensure that if the trigger is called recursively it will only be ran once.
    // Use it by specifying a "key" for the code segment it is being used for.  Each code segment should
    // have its own unique key.  For instance,
    //
    //    if (runOnce('For FieldSalesForecast.findOrCreateManagerForecasts')) {
    //       ... 
    //    }   
    //  
    public static Set<String> run = new Set<String>();
    public static boolean runOnce(String key) { if (run.contains(key)) { return false; } else { run.add(key); return true; } }  
    public static boolean hasRun(String key) { return run.contains(key); }  
    
    // A map of the Opportunity.ForecastCategory so it can be used
    // for Opportunity.Pilot_Forecast_Category__c setting of Forecast_Schedule.Stage__c
    private static Map<String,String> forecastCategoryNameMap;
    public static String getForecastCategoryValue(String name) {
        if (forecastCategoryNameMap == null) {
            forecastCategoryNameMap = new Map<String,String>();
            for( Schema.PicklistEntry f : Opportunity.ForecastCategory.getDescribe().getPicklistValues()) {
                forecastCategoryNameMap.put((f.getLabel() == 'Closed' ? 'Closed Won' : f.getLabel()), f.getValue());
            }
        }
        return forecastCategoryNameMap.containsKey(name) ? forecastCategoryNameMap.get(name) : name;
    }
    
    public static List<Opportunity> filterOpps(List<Opportunity> records, Map<Id, Opportunity> oldMap){
        List<Opportunity> result = new List<Opportunity>();
        for(Opportunity opp: records){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(oldOpp.Solution_Sales_Specialist__c != opp.Solution_Sales_Specialist__c || oldOpp.OwnerId != opp.OwnerId || oldOpp.OpportunityForecastOwner__c != opp.OpportunityForecastOwner__c || oldOpp.CloseDate != opp.CloseDate || oldOpp.ForecastCategory != opp.ForecastCategory || oldOpp.Pilot_Forecast_Category__c != opp.Pilot_Forecast_Category__c || oldOpp.Omit_From_Manager_Forecast__c != opp.Omit_From_Manager_Forecast__c){
                result.add(opp);
            }
        }
        return result;
    }
    // Opportunity: populates Field_Sales_Forecast__c lookup
    public static void findOrCreateForecasts( List<Opportunity> incomingOpportunities ) {
        //System.debug('Starting - FieldSalesForecast.findOrCreateForecasts( List<Opportunity> incomingOpportunities )');
        Set<Id> forecastOwners = new Set<Id>();
        Set<Date> startDates = new Set<Date>();
        if(incomingOpportunities.isEmpty()) return;
        for( Opportunity o : incomingOpportunities ) {
            Id ownerId = o.OpportunityForecastOwner__c == null ? o.OwnerId : o.OpportunityForecastOwner__c;
            forecastOwners.add( ownerId );
            if(o.Solution_Sales_Specialist__c != null)
                forecastOwners.add(o.Solution_Sales_Specialist__c);
            
            Date closestQuarter = getClosestQuarterStart( o.CloseDate );
            startDates.add( closestQuarter );
            //System.debug('Pre-Processing Opportunity(' + o.Id + ') StartDate(' + o.CloseDate + ') ClosestQuarter(' + closestQuarter + ')');
        }
        
        if(forecastOwners.isEmpty() || startDates.isEmpty()) return;
        // Get a list of the existing Field Sales Forecast so they can be updated
        List<Field_Sales_Forecast__c> existingForecasts = [
            SELECT Id, Start_Date__c, Forecast_Owner__c, Stage__c
            FROM Field_Sales_Forecast__c
            WHERE Forecast_Owner__c IN :forecastOwners
            AND Start_Date__c IN :startDates
        ];
        Map<String, Field_Sales_Forecast__c> forecastsMap = new Map<String, Field_Sales_Forecast__c>();
        for( Field_Sales_Forecast__c aForecast : existingForecasts ) {
            String forecastKey = generateForecastKey( aForecast.Start_Date__c, aForecast.Forecast_Owner__c, aForecast.Stage__c );
            forecastsMap.put( forecastKey, aForecast );
            //System.debug('Adding Existing Field Sales Forecast Key: ' + forecastKey);
        }
        
        List<Field_Sales_Forecast__c> newForecasts = new List<Field_Sales_Forecast__c>();
        //System.debug('Processing Opportunities...');
        for( Opportunity o : incomingOpportunities ) {
            if( (IGNORED_FORECAST_CATEGORIES.contains( o.ForecastCategory ) && IGNORED_PILOT_FORECAST_CATEGORIES.contains( o.Pilot_Forecast_Category__c ))
               || o.Omit_From_Manager_Forecast__c ) {
                   o.Field_Sales_Forecast__c = NULL;
                   //System.debug('Skipping Opportunity(' + o.Id + ')');
                   continue;
               }
            //System.debug('Processing Opportunity(' + o.Id + ')');
            Id ownerId = o.OpportunityForecastOwner__c == null ? o.OwnerId : o.OpportunityForecastOwner__c;
            // Create the new Field Sales Forecast record if it exists
            Date targetDate = getClosestQuarterStart( o.CloseDate );
            String targetForecastKey = generateForecastKey( targetDate, ownerId, o.ForecastCategory );
            //System.debug('Target Forecast Key(' + targetForecastKey + ')');
            
            if( !forecastsMap.containsKey( targetForecastKey ) ) {
                //System.debug('New Target Forecast Key(' + targetForecastKey + ') ForecastCategory/Pilot(' + o.ForecastCategory + '/false)');
                Field_Sales_Forecast__c newForecast = new Field_Sales_Forecast__c(
                    Forecast_Owner__c = ownerId,
                    OwnerId = ownerId,
                    Start_Date__c = targetDate,
                    Stage__c = o.ForecastCategory
                );
                
                newForecasts.add( newForecast );
                forecastsMap.put( targetForecastKey, newForecast );
            }
            if(o.Solution_Sales_Specialist__c != null){
                String solutionForecastKey = generateForecastKey(targetDate, o.Solution_Sales_Specialist__c, o.ForecastCategory);
                if( !forecastsMap.containsKey(solutionForecastKey)){
                    Field_Sales_Forecast__c newForecast = new Field_Sales_Forecast__c(Forecast_Owner__c = o.Solution_Sales_Specialist__c, OwnerId = o.Solution_Sales_Specialist__c, Start_Date__c = targetDate, Stage__c = o.ForecastCategory);
                    newForecasts.add( newForecast );
                    forecastsMap.put( solutionForecastKey, newForecast );
                }
            }
            // set the relation in case the field forecast doesn't exist yet
            o.Field_Sales_Forecast__r = forecastsMap.get( targetForecastKey );
            //System.debug('Setting Opportunity.Field_Sales_Forecast__r(' + o.Field_Sales_Forecast__r + ')');
            
            //System.debug('Completed Processing Opportunity(' + o.Id + ')');
        }
        
        try {
            insert newForecasts;
            //for (Field_Sales_Forecast__c f : newForecasts) {
              //  System.debug('INSERT Field_Sales_Forecast__c('+ f.Id + ')');
            //}
        }
        catch( System.DmlException dmlEx ) {
            //System.debug('DML Exception occurred');
            Map<String, List<Opportunity>> opportunitiesByForecastKey = getOpportunitiesByForecastKeyMap(incomingOpportunities);
            
            for( Integer index = 0; index < dmlEx.getNumDml(); index++ ) {
                Field_Sales_Forecast__c errorObject = newForecasts[ dmlEx.getDmlIndex(index) ];
                String errorKey = generateForecastKey( errorObject.Start_Date__c, errorObject.Forecast_Owner__c, errorObject.Stage__c );
                for( Opportunity errorOpportunity : opportunitiesByForecastKey.get( errorKey ) ) {
                    errorOpportunity.addError( dmlEx.getDmlMessage(index) );
                    //System.debug('DML Exception for Opportunity(' + errorOpportunity.Id + ') Message(' + dmlEx.getDmlMessage(index) + ')');
                }
            }
        }
        
        //System.debug('Starting update of Opportunity.Field_Sales_Forecast__c');
        for( Opportunity o : incomingOpportunities ) {
            //System.debug('Checking Opportunity(' + o.Id + ')');
            if( o.Field_Sales_Forecast__r != NULL ) {
                o.Field_Sales_Forecast__c = o.Field_Sales_Forecast__r.Id;
                //System.debug('Setting Opportunity.Field_Sales_Forecast__c(' + o.Field_Sales_Forecast__c + ')');
            }
        }
        //System.debug('Finished update of Opportunity.Field_Sales_Forecast__c');
        //System.debug('Finished - FieldSalesForecast.findOrCreateForecasts( List<Opportunity> incomingOpportunities )');
    }
    
    public static Map<String, List<Opportunity>> getOpportunitiesByForecastKeyMap(List<Opportunity> incomingOpportunities) {
        Map<String, List<Opportunity>> opportunitiesByForecastKey = new Map<String, List<Opportunity>>();
        for( Opportunity o : incomingOpportunities ) {
            // Create a key for the Field Sales Forecast records
            Date closestQuarter = getClosestQuarterStart( o.CloseDate );
            Id ownerId = o.OpportunityForecastOwner__c == null ? o.OwnerId : o.OpportunityForecastOwner__c;
            String opportunityKey = generateForecastKey( closestQuarter, ownerId, o.ForecastCategory);
            if( !opportunitiesByForecastKey.containsKey( opportunityKey ) ) {
                opportunitiesByForecastKey.put( opportunityKey, new List<Opportunity>() );
            }
            opportunitiesByForecastKey.get( opportunityKey ).add( o );
            
            // Create a key for the Pilot Field Sales Forecast records
            String opportunityPilotKey = generateForecastKey( closestQuarter, ownerId, o.Pilot_Forecast_Category__c );
            if( !opportunitiesByForecastKey.containsKey( opportunityPilotKey ) ) {
                opportunitiesByForecastKey.put( opportunityPilotKey, new List<Opportunity>() );
            }
            opportunitiesByForecastKey.get( opportunityPilotKey ).add( o );
        }
        return opportunitiesByForecastKey;
    }
    
    // Opportunity: recalculates Raw Contract Value on related Field_Sales_Forecast__c
    public static void updateSalesForecastsContractValues( List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities ) {
        Set<Id> fieldForecastsToUpdate = new Set<Id>();
        for( Opportunity anOpportunity : newOpportunities ) {
            if( oldOpportunities != NULL && oldOpportunities.containsKey( anOpportunity.Id ) ) {
                Opportunity oldOpportunity = oldOpportunities.get( anOpportunity.Id );
                if( anOpportunity.Amount != oldOpportunity.Amount ) {
                    fieldForecastsToUpdate.add( anOpportunity.Field_Sales_Forecast__c );
                }
                if( anOpportunity.Field_Sales_Forecast__c != oldOpportunity.Field_Sales_Forecast__c ) {
                    fieldForecastsToUpdate.add( anOpportunity.Field_Sales_Forecast__c );
                    fieldForecastsToUpdate.add( oldOpportunity.Field_Sales_Forecast__c );
                }
            }
            else {
                fieldForecastsToUpdate.add( anOpportunity.Field_Sales_Forecast__c );
            }
        }
        fieldForecastsToUpdate.remove( NULL );
        if(fieldForecastsToUpdate.isEmpty()) return;
        
        List<AggregateResult> opportunitySums = [ SELECT SUM(Amount) sum, Field_Sales_Forecast__c
                                                 FROM Opportunity
                                                 WHERE Field_Sales_Forecast__c IN :fieldForecastsToUpdate
                                                 GROUP BY Field_Sales_Forecast__c ];
        Map<Id, Double> forecastSums = new Map<Id, Double>();
        for( AggregateResult aSum : opportunitySums ) {
            forecastSums.put( (Id)aSum.get('Field_Sales_Forecast__c'), (Double)aSum.get('sum') );
        }
        
        List<Field_Sales_Forecast__c> forecastsToUpdate = new List<Field_Sales_Forecast__c>();
        for( Id aForecastId : fieldForecastsToUpdate ) {
            Field_Sales_Forecast__c updateForecast = new Field_Sales_Forecast__c( Id = aForecastId );
            updateForecast.Contract_Value_Amount__c = 0.0;
            if( forecastSums.containsKey( aForecastId ) ) {
                updateForecast.Contract_Value_Amount__c = forecastSums.get( aForecastId );
            }
            forecastsToUpdate.add( updateForecast );
        }
        
        // Recalculated Opportunities need to have their Forecast Schedules reprocessed in case they should
        // be associated with a different Field Sales Forecast.
        //
        // Recalulated Opportunity are when either:
        //    - Its related Field_Sales_Forecast__c changes
        //    - Its Pilot_Forecast_Category__c changes
        List<Opportunity> recalculatedOpportunities = new List<Opportunity>();
        for( Opportunity anOpportunity : newOpportunities ) {
            if( oldOpportunities != NULL && oldOpportunities.containsKey( anOpportunity.Id ) ) {
                Opportunity oldOpp = oldOpportunities.get( anOpportunity.Id );
                if (
                    (oldOpp.Field_Sales_Forecast__c != anOpportunity.Field_Sales_Forecast__c) ||
                    (oldOpp.Pilot_Forecast_Category__c != anOpportunity.Pilot_Forecast_Category__c)
                ) {
                    recalculatedOpportunities.add( anOpportunity );
                }
            }
        }
        
        try {
            update forecastsToUpdate;
        }
        catch( System.DmlException ex ) {
            Map<Id, List<Opportunity>> opportunitiesForForecasts = getOpportunitiesByFieldSalesForecastIdMap(newOpportunities, oldOpportunities);
            
            for( Integer index = 0; index < ex.getNumDml(); index++ ) {
                Id errorId = forecastsToUpdate[ ex.getDmlIndex(index) ].Id;
                for( Opportunity triggerOpportunity : opportunitiesForForecasts.get( errorId ) ) {
                    triggerOpportunity.addError( ex.getDmlMessage(index) );
                }
            }
        }
        
        // For any recalculated Opportunities reprocess the Forecast Schedules in case they should
        // be associated with a different Field Sales Forecast 
        if( !recalculatedOpportunities.isEmpty() ) {
            List<Forecast_Schedule__c> schedulesToRecalculate = [
                SELECT Id, Opportunity__c, Start_Date__c, Is_Pilot__c
                FROM Forecast_Schedule__c
                WHERE Opportunity__c IN :recalculatedOpportunities
                ORDER BY Start_Date__c
            ];
            for (Forecast_Schedule__c s : schedulesToRecalculate) {
                System.debug('Forecast Schedule to be recalculated - ' + s);
            }
            
            try {
                update schedulesToRecalculate;
            } catch( System.DmlException dmlEx ) {
                Map<Id, Opportunity> opportunitiesMap = new Map<Id, Opportunity>( newOpportunities );
                for( Integer index = 0; index < dmlEx.getNumDml(); index++ ) {
                    Id errorId = schedulesToRecalculate[ dmlEx.getDmlIndex(index) ].Opportunity__c;
                    opportunitiesMap.get( errorId ).addError( dmlEx.getDmlMessage(index) );
                }
            }
        }
    }
    
    public static Map<Id, List<Opportunity>> getOpportunitiesByFieldSalesForecastIdMap(List<Opportunity> newOpportunities, Map<Id,Opportunity> oldOpportunities) {
        Map<Id, List<Opportunity>> opportunitiesForForecasts = new Map<Id, List<Opportunity>>();
        for( Opportunity anOpportunity : newOpportunities ) {
            if( !opportunitiesForForecasts.containsKey( anOpportunity.Field_Sales_Forecast__c ) ) {
                opportunitiesForForecasts.put( anOpportunity.Field_Sales_Forecast__c, new List<Opportunity>() );
            }
            opportunitiesForForecasts.get( anOpportunity.Field_Sales_Forecast__c ).add( anOpportunity );
            
            if( oldOpportunities != NULL && oldOpportunities.containsKey( anOpportunity.Id ) ) {
                Opportunity oldOpportunity = oldOpportunities.get( anOpportunity.Id );
                if( !opportunitiesForForecasts.containsKey( oldOpportunity.Field_Sales_Forecast__c ) ) {
                    opportunitiesForForecasts.put( oldOpportunity.Field_Sales_Forecast__c, new List<Opportunity>() );
                }
                opportunitiesForForecasts.get( oldOpportunity.Field_Sales_Forecast__c ).add( anOpportunity );
            }
        }
        return opportunitiesForForecasts;
    }
    
    // Forecast_Schedule__c: populate Field_Sales_Forecast__c lookup
    public static void findOrCreateForecasts( List<Forecast_Schedule__c> incomingSchedules ) {
        System.debug('Starting - FieldSalesForecast.findOrCreateForecasts( List<Forecast_Schedule__c> incomingSchedules )');
        Set<Id> opportunityIds = new Set<Id>();
        Set<Date> startDates = new Set<Date>();
        for( Forecast_Schedule__c s : incomingSchedules ) {
            opportunityIds.add( s.Opportunity__c );
            
            if( s.Start_Date__c != NULL ) {
                startDates.add( getClosestQuarterStart( s.Start_Date__c ) );
            }
            System.debug('Pre-Processing Forecast_Schedule__c(' + s.Id + ') Opportunity(' + s.Opportunity__c + ') StartDate(' + s.Start_Date__c + ') ClosestQuarter(' + getClosestQuarterStart( s.Start_Date__c ) + ')');
        }
        
        // If all Forecast Schedule records were for pilots then stop processing
        if (opportunityIds.isEmpty()) return;
        
        System.debug('Build opportunitiesMap map...');
        Map<Id, Opportunity> opportunitiesMap = new Map<Id, Opportunity>([
            SELECT Id, OwnerId, ForecastCategory, Pilot_Forecast_Category__c, Omit_From_Manager_Forecast__c, OpportunityForecastOwner__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);
        System.debug('Build ownerIds map...');
        Set<Id> ownerIds = new Set<Id>();
        for( Opportunity anOpportunity : opportunitiesMap.values() ) {
            Id ownerId = anOpportunity.OpportunityForecastOwner__c == null ? anOpportunity.OwnerId : anOpportunity.OpportunityForecastOwner__c;
            ownerIds.add( ownerId );
        }
        
        System.debug('Build existingForecasts map...');
        if(ownerIds.isEmpty() || startDates.isEmpty()) return;
        List<Field_Sales_Forecast__c> existingForecasts = [
            SELECT Id, Forecast_Owner__c, Start_Date__c, Stage__c
            FROM Field_Sales_Forecast__c
            WHERE Forecast_Owner__c IN :ownerIds
            AND Start_Date__c IN :startDates
        ];
        System.debug('Build forecastsMap map...');
        Map<String, Field_Sales_Forecast__c> forecastsMap = new Map<String, Field_Sales_Forecast__c>();
        for( Field_Sales_Forecast__c f : existingForecasts ) {
            String forecastKey = generateForecastKey( f.Start_Date__c, f.Forecast_Owner__c, f.Stage__c );
            forecastsMap.put( forecastKey, f );
            System.debug('Adding Existing Forecast Key: ' + forecastKey + ' Start_Date__c(' + f.Start_Date__c + ') Stage__c(' + f.Stage__c + ')');
        }
        
        System.debug('Processing Forecast_Schedule__c records...');
        List<Field_Sales_Forecast__c> newForecasts = new List<Field_Sales_Forecast__c>();
        for( Forecast_Schedule__c s : incomingSchedules ) {
            System.debug('Processing Forecast_Schedule__c(' + s.Id + ')');
            Opportunity o = opportunitiesMap.get( s.Opportunity__c );
            
            // Unrelate the Forecast_Schedule__c from a Field Sales Forecast if any of the following are true:
            //    Start date not set
            //    Is omitted from the manager forecast
            //	If not a pilot the forecast category is omitted
            //	If a pilot the pilot forecast category is omitted
            System.debug('Checking required fields:  Start_Date__c not null(' + s.Start_Date__c + '))');
            System.debug('Checking required fields:  Omit_From_Manager_Forecast__c not true(' + o.Omit_From_Manager_Forecast__c + ')');
            System.debug('Checking required fields:  Non-Pilot/ForecastCategory not Omitted(' + !s.Is_Pilot__c + '/' + o.ForecastCategory + ')');
            System.debug('Checking required fields:  OR Pilot/Pilot_Forecast_Category__c not Omitted(' + s.Is_Pilot__c + '/' + o.ForecastCategory + ') Omit_From_Manager_Forecast__c not true(' + o.Omit_From_Manager_Forecast__c + ')');
            
            if( s.Start_Date__c == NULL
               || (!s.Is_Pilot__c && IGNORED_FORECAST_CATEGORIES.contains( o.ForecastCategory ))
               || (s.Is_Pilot__c && IGNORED_PILOT_FORECAST_CATEGORIES.contains( o.Pilot_Forecast_Category__c ))
               || o.Omit_From_Manager_Forecast__c ) {
                   s.Field_Sales_Forecast__c = NULL;
                   System.debug('Unrelate Forecast_Schedule__c from Field_Sales_Forecast__c');
                   continue;
               }
            Id ownerId = o.OpportunityForecastOwner__c == null ? o.ownerId : o.OpportunityForecastOwner__c;
            // Create a Field Sales Forecast record if it does not already exist
            Date targetDate = getClosestQuarterStart( s.Start_Date__c );
            System.debug('Checking Schedule Forecast Fields: Forecast_Schedule__c.Id(' + s.Id + ') targetDate(' + targetDate + ') ForecastCategory(' + o.ForecastCategory + ') Pilot_Forecast_Category__c(' + o.Pilot_Forecast_Category__c + ') Is_Pilot__c(' + s.Is_Pilot__c + ')');
            String scheduleKey = generateForecastKey( targetDate, ownerId, (s.Is_Pilot__c ? getForecastCategoryValue(o.Pilot_Forecast_Category__c) : o.ForecastCategory) );
            System.debug('Checking Schedule Forecast Key: ' + scheduleKey);
            
            if( !forecastsMap.containsKey( scheduleKey ) ) {
                System.debug('New Schedule Field Sales Forecast Key: ' + scheduleKey + ' ForecastCategory(' + o.ForecastCategory + ')');
                Field_Sales_Forecast__c newForecast = new Field_Sales_Forecast__c(
                    Start_Date__c = targetDate,
                    Forecast_Owner__c = ownerId,
                    OwnerId = ownerId,
                    Stage__c = (s.Is_Pilot__c ? getForecastCategoryValue(o.Pilot_Forecast_Category__c) : o.ForecastCategory)
                );
                
                forecastsMap.put( scheduleKey, newForecast );
                newForecasts.add( newForecast );
            }
            
            s.Field_Sales_Forecast__r = forecastsMap.get( scheduleKey );
        }
        
        try {
            insert newForecasts;
            for (Field_Sales_Forecast__c f : newForecasts) {
                System.debug('INSERT Field_Sales_Forecast__c('+ f.Id + ')');
            }
        }
        catch( System.DmlException ex ) {
            System.debug('DML Exception occurred');
            /*Map<String, List<Forecast_Schedule__c>> keyToSchedules = new Map<String, List<Forecast_Schedule__c>>();
for( Forecast_Schedule__c s : incomingSchedules ) {

// Create a key for the Field Sales Forecast records
Date targetDate = getClosestQuarterStart( s.Start_Date__c );
Opportunity o = opportunitiesMap.get( s.Opportunity__c );
Id ownerId = o.OpportunityForecastOwner__c == null ? o.OwnerId : o.OpportunityForecastOwner__c;
String scheduleKey = generateForecastKey( targetDate, ownerId, (s.Is_Pilot__c ? getForecastCategoryValue(o.Pilot_Forecast_Category__c) : o.ForecastCategory) );
if( !keyToSchedules.containsKey( scheduleKey ) ) {
keyToSchedules.put( scheduleKey, new List<Forecast_Schedule__c>() );
}
keyToSchedules.get( scheduleKey ).add( s );
}

for( Integer index = 0; index < ex.getNumDml(); index++ ) {
Field_Sales_Forecast__c errorObject = newForecasts[ ex.getDmlIndex(index) ];
String errorKey = generateForecastKey( errorObject.Start_Date__c, errorObject.Forecast_Owner__c, errorObject.Stage__c );
for( Forecast_Schedule__c s : keyToSchedules.get( errorKey ) ) {
s.addError( ex.getDmlMessage(index) );
System.debug('DML Exception for Forecast_Schedule__c(' + s.Id + ') Message(' + ex.getDmlMessage(index) + ')');
}
}*/
        }
        
        for( Forecast_Schedule__c s : incomingSchedules ) {
            if( s.Field_Sales_Forecast__r != NULL ) {
                s.Field_Sales_Forecast__c = s.Field_Sales_Forecast__r.Id;
            }
        }
        System.debug('Finished update of Opportunity.Field_Sales_Forecast__c');
        System.debug('Finished - FieldSalesForecast.findOrCreateForecasts( List<Forecast_Schedule__c> incomingSchedules )');
    }
    
    
    // Forecast_Schedule__c: recalculate Raw Waterfall(Forecast) Amount on related Field_Sales_Forecast__c
    public static void updateSalesForecastsScheduleValues( List<Forecast_Schedule__c> incomingSchedules, List<Forecast_Schedule__c> oldSchedules ) {
        Map<Id, Field_Sales_Forecast__c> relatedSalesForecasts = new Map<Id, Field_Sales_Forecast__c>();
        for( Forecast_Schedule__c aSchedule : incomingSchedules ) {
            if( !relatedSalesForecasts.containsKey( aSchedule.Field_Sales_Forecast__c )
               && !String.isBlank( aSchedule.Field_Sales_Forecast__c ) ) {
                   Field_Sales_Forecast__c relatedForecast = new Field_Sales_Forecast__c();
                   relatedForecast.Id = aSchedule.Field_Sales_Forecast__c;
                   relatedForecast.Sales_Forecast_Amount__c = 0.0;
                   relatedForecast.Sales_Current_Quarter__c = 0.0;
                   relatedSalesForecasts.put( aSchedule.Field_Sales_Forecast__c, relatedForecast );
               }
        }
        if( oldSchedules != NULL && !oldSchedules.isEmpty() ) {
            for( Forecast_Schedule__c oldSchedule : oldSchedules ) {
                if( !String.isBlank( oldSchedule.Field_Sales_Forecast__c )
                   && !relatedSalesForecasts.containsKey( oldSchedule.Field_Sales_Forecast__c ) ) {
                       Field_Sales_Forecast__c relatedForecast = new Field_Sales_Forecast__c();
                       relatedForecast.Id = oldSchedule.Field_Sales_Forecast__c;
                       relatedForecast.Sales_Forecast_Amount__c = 0.0;
                       relatedForecast.Sales_Current_Quarter__c = 0.0;
                       relatedSalesForecasts.put( oldSchedule.Field_Sales_Forecast__c, relatedForecast );
                   }
            }
        }
        if(relatedSalesForecasts.isEmpty()) return;
        List<Forecast_Schedule__c> existingSchedules = [ SELECT Forecast_Amount__c, Start_Date__c,
                                                        Field_Sales_Forecast__r.Start_Date__c, Opportunity__c
                                                        FROM Forecast_Schedule__c
                                                        WHERE Field_Sales_Forecast__c IN :relatedSalesForecasts.keySet()
                                                       ];
        Set<Id> opportunityIds = new Set<Id>();
        for( Forecast_Schedule__c aSchedule : existingSchedules ) {
            opportunityIds.add( aSchedule.Opportunity__c );
        }
        Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>([ SELECT Id, CloseDate FROM Opportunity WHERE Id IN :opportunityIds ]);
        
        for( Forecast_Schedule__c aResult : existingSchedules ) {
            Field_Sales_Forecast__c relatedForecast = relatedSalesForecasts.get( aResult.Field_Sales_Forecast__c );
            relatedForecast.Sales_Forecast_Amount__c += aResult.Forecast_Amount__c;
            
            Opportunity relatedOpportunity = opportunities.get( aResult.Opportunity__c );
            if( getClosestQuarterStart( relatedOpportunity.CloseDate ) == getClosestQuarterStart( aResult.Field_Sales_Forecast__r.Start_Date__c ) ) {
                relatedForecast.Sales_Current_Quarter__c += aResult.Forecast_Amount__c;
            }
        }
        existingSchedules.clear();
        try {
            update relatedSalesForecasts.values();
        }
        catch( System.DmlException ex ) {
            Map<Id, List<Forecast_Schedule__c>> salesForecastToSchedules = new Map<Id, List<Forecast_Schedule__c>>();
            for( Forecast_Schedule__c aSchedule : incomingSchedules ) {
                if( !salesForecastToSchedules.containsKey( aSchedule.Field_Sales_Forecast__c ) ) {
                    salesForecastToSchedules.put( aSchedule.Field_Sales_Forecast__c, new List<Forecast_Schedule__c>() );
                }
                salesForecastToSchedules.get( aSchedule.Field_Sales_Forecast__c ).add( aSchedule );
            }
            if( oldSchedules != NULL && !oldSchedules.isEmpty() ) {
                Map<Id, Forecast_Schedule__c> newForecastsMap = new Map<Id, Forecast_Schedule__c>(incomingSchedules);
                for( Forecast_Schedule__c oldSchedule : oldSchedules ) {
                    if( !salesForecastToSchedules.containsKey( oldSchedule.Field_Sales_Forecast__c ) ) {
                        salesForecastToSchedules.put( oldSchedule.Field_Sales_Forecast__c, new List<Forecast_Schedule__c>() );
                    }
                    salesForecastToSchedules.get( oldSchedule.Field_Sales_Forecast__c ).add( newForecastsMap.get(oldSchedule.Id) );
                }
            }
            
            for( Integer index = 0; index < ex.getNumDml(); index++ ) {
                Id errorId = relatedSalesForecasts.values()[ ex.getDmlIndex(index) ].Id;
                for( Forecast_Schedule__c aSchedule : salesForecastToSchedules.get(errorId) ) {
                    aSchedule.addError( ex.getDmlMessage(index) );
                }
            }
        }
    }
    
    // Field_Sales_Forecast__c: populates Manager_Forecast__c lookup
    public static void findOrCreateManagerForecasts( List<Field_Sales_Forecast__c> incomingForecasts ) {
        // If this running as batch and has already run once for this transaction then do not run again
        if (System.isBatch() && hasRun('For FieldSalesForecast.findOrCreateManagerForecasts 2nd Run'))
            return;
        if (System.isBatch() && runOnce('For FieldSalesForecast.findOrCreateManagerForecasts 1st Run'))
            runOnce('For FieldSalesForecast.findOrCreateManagerForecasts 2nd Run');
        
        Set<Id> forecastOwners = new Set<Id>();
        Set<Date> startDates = new Set<Date>();
        for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
            forecastOwners.add( aForecast.Forecast_Owner__c );
            startDates.add( getClosestQuarterStart( aForecast.Start_Date__c ) );
        }
        
        Map<Id, Id> managerIdsMap = new Map<Id, Id>();
        if(forecastOwners.isEmpty()) return;
        for( User aForecastOwner : [ SELECT Id, ManagerId FROM User WHERE Id IN :forecastOwners ] ) {
            managerIdsMap.put( aForecastOwner.Id, aForecastOwner.ManagerId );
        }
        
        Map<String, Field_Sales_Forecast__c> forecastsMap = new Map<String, Field_Sales_Forecast__c>();
        for( Field_Sales_Forecast__c managerForecast :  [ SELECT Id, Forecast_Owner__c, Start_Date__c, Stage__c
                                                         FROM Field_Sales_Forecast__c
                                                         WHERE Start_Date__c IN :startDates
                                                         AND Forecast_Owner__c IN :managerIdsMap.values() ]) {
                                                             String forecastKey = generateForecastKey( managerForecast.Start_Date__c, managerForecast.Forecast_Owner__c, managerForecast.Stage__c );
                                                             forecastsMap.put( forecastKey, managerForecast );
                                                         }
        
        List<Field_Sales_Forecast__c> newForecasts = new List<Field_Sales_Forecast__c>();
        for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
            Id managerId = managerIdsMap.get( aForecast.Forecast_Owner__c );
            if( aForecast.Stage__c == NULL || String.isBlank( managerId ) ) continue;
            
            Date quarterStart = getClosestQuarterStart( aForecast.Start_Date__c );
            String forecastKey = generateForecastKey( quarterStart, managerId, aForecast.Stage__c );
            
            if( !forecastsMap.containsKey( forecastKey ) ) {
                Field_Sales_Forecast__c newForecast = new Field_Sales_Forecast__c();
                newForecast.Forecast_Owner__c = managerId;
                newForecast.OwnerId = newForecast.Forecast_Owner__c;
                newForecast.Start_Date__c = quarterStart;
                newForecast.Stage__c = aForecast.Stage__c;
                
                newForecasts.add( newForecast );
                forecastsMap.put( forecastKey, newForecast );
            }
            
            // set the relation in case the manager forecast doesn't exist yet
            aForecast.Manager_Forecast__r = forecastsMap.get( forecastKey );
        }
        
        try {
            insert newForecasts;
        }
        catch( System.DmlException dmlEx ) {
            Map<String, List<Field_Sales_Forecast__c>> salesForecastsByForecastKey = getSalesForecastsByManagerForecastKey(incomingForecasts, managerIdsMap);
            
            for( Integer index = 0; index < dmlEx.getNumDml(); index++ ) {
                Field_Sales_Forecast__c errorObject = newForecasts[ dmlEx.getDmlIndex(index) ];
                Date quarterStart = getClosestQuarterStart( errorObject.Start_Date__c );
                String errorKey = generateForecastKey( quarterStart, errorObject.Forecast_Owner__c, errorObject.Stage__c );
                for( Field_Sales_Forecast__c errorForecast : salesForecastsByForecastKey.get( errorKey ) ) {
                    errorForecast.addError( dmlEx.getDmlMessage(index) );
                }
            }
        }
        
        for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
            if( aForecast.Manager_Forecast__r != NULL ) {
                aForecast.Manager_Forecast__c = aForecast.Manager_Forecast__r.Id;
            }
        }
    }
    
    public static Map<String, List<Field_Sales_Forecast__c>> getSalesForecastsByManagerForecastKey(List<Field_Sales_Forecast__c> incomingForecasts, Map<Id,Id> managerIdsMap) {
        Map<String, List<Field_Sales_Forecast__c>> salesForecastsByForecastKey = new Map<String, List<Field_Sales_Forecast__c>>();
        for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
            Id managerId = managerIdsMap.get( aForecast.Forecast_Owner__c );
            Date quarterStart = getClosestQuarterStart( aForecast.Start_Date__c );
            String forecastKey = generateForecastKey( quarterStart, managerId, aForecast.Stage__c );
            if( !salesForecastsByForecastKey.containsKey( forecastKey ) ) {
                salesForecastsByForecastKey.put( forecastKey, new List<Field_Sales_Forecast__c>() );
            }
            salesForecastsByForecastKey.get( forecastKey ).add( aForecast );
        }
        return salesForecastsByForecastKey;
    }
    
    // Field_Sales_Forecast__c: populates Override_Forecast__c lookup
    public static void findOrCreateOverrideForecasts( List<Field_Sales_Forecast__c> incomingForecasts ) {
        Set<Id> forecastOwners = new Set<Id>();
        Set<Date> startDates = new Set<Date>();
        for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
            forecastOwners.add( aForecast.Forecast_Owner__c );
            startDates.add( getClosestQuarterStart( aForecast.Start_Date__c ) );
        }
        
        if(forecastOwners.isEmpty() || startDates.isEmpty()) return; 
        // DEVNOTE - May need to exclude pilot field sales forecast records
        Map<String, Field_Sales_Forecast__c> forecastsMap = new Map<String, Field_Sales_Forecast__c>();
        for( Field_Sales_Forecast__c overrideForecast : [ SELECT Id, Forecast_Owner__c, Start_Date__c
                                                         FROM Field_Sales_Forecast__c
                                                         WHERE Start_Date__c IN :startDates
                                                         AND Forecast_Owner__c IN :forecastOwners
                                                         AND Stage__c = NULL ] ) {
                                                             String forecastKey = generateForecastKey( overrideForecast.Start_Date__c, overrideForecast.Forecast_Owner__c );
                                                             forecastsMap.put( forecastKey, overrideForecast );
                                                         }
        
        List<Field_Sales_Forecast__c> newForecasts = new List<Field_Sales_Forecast__c>();
        for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
            if( aForecast.Stage__c == NULL ) continue;
            
            Date quarterStart = getClosestQuarterStart( aForecast.Start_Date__c );
            String forecastKey = generateForecastKey( quarterStart, aForecast.Forecast_Owner__c );
            
            if( !forecastsMap.containsKey( forecastKey ) ) {
                Field_Sales_Forecast__c newForecast = new Field_Sales_Forecast__c();
                newForecast.Forecast_Owner__c = aForecast.Forecast_Owner__c;
                newForecast.OwnerId = newForecast.Forecast_Owner__c;
                newForecast.Start_Date__c = quarterStart;
                
                newForecasts.add( newForecast );
                forecastsMap.put( forecastKey, newForecast );
            }
            
            // set the relation in case the manager forecast doesn't exist yet
            aForecast.Override_Forecast__r = forecastsMap.get( forecastKey );
        }
        
        try {
            insert newForecasts;
        }
        catch( System.DmlException dmlEx ) {
            Map<String, List<Field_Sales_Forecast__c>> salesForecastsByForecastKey = getSalesForecastsByOverrideForecastKey(incomingForecasts);
            
            for( Integer index = 0; index < dmlEx.getNumDml(); index++ ) {
                Field_Sales_Forecast__c errorObject = newForecasts[ dmlEx.getDmlIndex(index) ];
                Date quarterStart = getClosestQuarterStart( errorObject.Start_Date__c );
                String errorKey = generateForecastKey( quarterStart, errorObject.Forecast_Owner__c );
                for( Field_Sales_Forecast__c errorForecast : salesForecastsByForecastKey.get( errorKey ) ) {
                    errorForecast.addError( dmlEx.getDmlMessage(index) );
                }
            }
        }
        
        for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
            if( aForecast.Override_Forecast__r != NULL ) {
                aForecast.Override_Forecast__c = aForecast.Override_Forecast__r.Id;
            }
        }
    }
    
    public static Map<String, List<Field_Sales_Forecast__c>> getSalesForecastsByOverrideForecastKey(List<Field_Sales_Forecast__c> incomingForecasts) {
        Map<String, List<Field_Sales_Forecast__c>> salesForecastsByForecastKey = new Map<String, List<Field_Sales_Forecast__c>>();
        for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
            Date quarterStart = getClosestQuarterStart( aForecast.Start_Date__c );
            String forecastKey = generateForecastKey( quarterStart, aForecast.Forecast_Owner__c );
            if( !salesForecastsByForecastKey.containsKey( forecastKey ) ) {
                salesForecastsByForecastKey.put( forecastKey, new List<Field_Sales_Forecast__c>() );
            }
            salesForecastsByForecastKey.get( forecastKey ).add( aForecast );
        }
        return salesForecastsByForecastKey;
    }
    
    // Field_Sales_Forecast__c: push values to Override forecast record
    public static void updateOverrideForecasts( List<Field_Sales_Forecast__c> incomingForecasts ) {
        Map<Id, Field_Sales_Forecast__c> overrideForecastsMap = new Map<Id, Field_Sales_Forecast__c>();
        for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
            if( !String.isBlank( aForecast.Override_Forecast__c )
               && !overrideForecastsMap.containsKey( aForecast.Override_Forecast__c ) ) {
                   Field_Sales_Forecast__c overrideForecast = new Field_Sales_Forecast__c();
                   overrideForecast.Id = aForecast.Override_Forecast__c;
                   overrideForecast.Manager_Raw_Forecast_Rollup__c = 0.0;
                   overrideForecast.Manager_Raw_Contract_Rollup__c = 0.0;
                   overrideForecast.Manager_Modified_Forecast_Rollup__c = 0.0;
                   overrideForecast.Manager_Modified_Contract_Rollup__c = 0.0;
                   overrideForecast.Manager_Raw_Deal_Rollup__c = 0.0;
                   overrideForecast.Manager_Raw_Opp_Rollup__c = 0.0;
                   overrideForecast.Manager_Modified_Deal__c = 0.0;
                   overrideForecast.Manager_Modified_Opp__c = 0.0;
                   overrideForecast.Manager_Raw_Deal_Forecast_Rollup__c = 0.0;
                   overrideForecast.Manager_Raw_Booking_Rollup__c = 0.0;
                   overrideForecast.Manager_Modified_Booking__c = 0.0;
                   overrideForecast.Manager_Modified_Deal_Forecast__c = 0.0;
                   overrideForecast.Manager_Raw_eARR_Rollup__c = 0.0;
                   overrideForecast.Manager_Booking_eARR_Rollup__c = 0.0;
                   overrideForecast.Manager_Modified_eARR__c = 0.0;
                   overrideForecast.Manager_Modified_Booking_eARR__c = 0.0;
                   overrideForecast.Manager_Modified_Deal_eARR__c = 0.0;
                   overrideForecast.Manager_Modified_Booking_Deal__c = 0.0;
                   overrideForecast.Manager_Modified_Booking_Deal_eARR__c = 0.0;
                   overrideForecast.Manager_Deal_eARR_Rollup__c = 0.0;
                   overrideForecast.Manager_Booking_Deal_Rollup__c = 0.0;
                   overrideForecast.Manager_Booking_Deal_eARR_Rollup__c = 0.0;
                   overrideForecastsMap.put( aForecast.Override_Forecast__c, overrideForecast );
               }
        }
        
        if(overrideForecastsMap.isEmpty()) return;
        List<Field_Sales_Forecast__c> forecasts = [ SELECT Override_Forecast__c, Sales_Forecast_Override__c,
                                                   Sales_Forecast_Amount__c, Contract_Value_Override__c,
                                                   Contract_Value_Amount__c, Submanager_Contract_Total__c,
                                                   Submanager_Forecast_Total__c, Submanager_Modified_Contract__c,
                                                   Submanager_Modified_Forecast__c, Deal_Forecast_Override__c,
                                                   Raw_Quota_Forecast_Rollup__c, Submanager_Modified_Deal__c,
                                                   Opp_Forecast_Override__c, Raw_Revenue_Forecast_Rollup__c,
                                                   Submanager_Modified_Opp__c, Submanager_Deal_Total__c,
                                                   Submanager_Opp_Total__c, Submanager_Deal_Forecast_Total__c,
                                                   Submanager_Booking_Total__c, Total_Deal_Forecast__c,
                                                   Total_Bookings_Forecast__c, Deal_Forecast_Amount_Override__c,
                                                   Booking_Forecast_Override__c, Submanager_Modified_Deal_Forecast__c,
                                                   Submanager_Modified_Booking__c, Total_eARR__c, Total_Booking_eARR__c,
                                                   Booking_eARR_Override__c, eARR_Override__c, Submanager_Modified_Booking_eARR__c,
                                                   Submanager_Modified_eARR__c, Deal_eARR_Override__c, Booking_Deal_eARR_Override__c,
                                                   Booking_Deal_Override__c, Submanager_Modified_Deal_eARR__c, Submanager_Modified_Booking_Deal__c,
                                                   Submanager_Modified_Booking_Deal_eARR__c, Total_Deal_eARR__c, Total_Booking_Deal__c,
                                                   Total_Booking_Deal_eARR__c, Submanager_Deal_eARR_Total__c, Submanager_Booking_Deal_Total__c,
                                                   Submanager_Booking_Deal_eARR_Total__c
                                                   
                                                   FROM Field_Sales_Forecast__c
                                                   WHERE Override_Forecast__c IN :overrideForecastsMap.keySet() ];
        for( Field_Sales_Forecast__c aForecast : forecasts ) {
            Field_Sales_Forecast__c overrideForecast = overrideForecastsMap.get( aForecast.Override_Forecast__c );
            overrideForecast.Manager_Raw_Forecast_Rollup__c += getDoubleOrZero( aForecast.Sales_Forecast_Amount__c ) + getDoubleOrZero( aForecast.Submanager_Forecast_Total__c );
            overrideForecast.Manager_Raw_Contract_Rollup__c += getDoubleOrZero( aForecast.Contract_Value_Amount__c ) + getDoubleOrZero( aForecast.Submanager_Contract_Total__c );
            overrideForecast.Manager_Raw_Deal_Rollup__c += getDoubleOrZero( aForecast.Raw_Quota_Forecast_Rollup__c ) + getDoubleOrZero( aForecast.Submanager_Deal_Total__c);
            overrideForecast.Manager_Raw_Opp_Rollup__c += getDoubleOrZero( aForecast.Raw_Revenue_Forecast_Rollup__c) + getDoubleOrZero( aForecast.Submanager_Opp_Total__c);
            overrideForecast.Manager_Raw_Deal_Forecast_Rollup__c += getDoubleOrZero(aForecast.Total_Deal_Forecast__c) + getDoubleOrZero( aForecast.Submanager_Deal_Forecast_Total__c);
            overrideForecast.Manager_Raw_Booking_Rollup__c += getDoubleOrZero( aForecast.Total_Bookings_Forecast__c) + getDoubleOrZero( aForecast.Submanager_Booking_Total__c);
            overrideForecast.Manager_Deal_eARR_Rollup__c += getDoubleOrZero( aForecast.Total_Deal_eARR__c) + getDoubleOrZero( aForecast.Submanager_Deal_eARR_Total__c);
            overrideForecast.Manager_Booking_Deal_Rollup__c += getDoubleOrZero( aForecast.Total_Booking_Deal__c) + getDoubleOrZero( aForecast.Submanager_Booking_Deal_Total__c);
            overrideForecast.Manager_Booking_Deal_eARR_Rollup__c += getDoubleOrZero( aForecast.Total_Booking_Deal_eARR__c) + getDoubleOrZero( aForecast.Submanager_Booking_Deal_eARR_Total__c);
            if( aForecast.Sales_Forecast_Override__c == NULL ) {
                overrideForecast.Manager_Modified_Forecast_Rollup__c += getDoubleOrZero( aForecast.Sales_Forecast_Amount__c ) + getDoubleOrZero( aForecast.Submanager_Modified_Forecast__c );
            } else {
                overrideForecast.Manager_Modified_Forecast_Rollup__c += aForecast.Sales_Forecast_Override__c;
            }
            
            if( aForecast.Contract_Value_Override__c == NULL ) {
                overrideForecast.Manager_Modified_Contract_Rollup__c += getDoubleOrZero( aForecast.Contract_Value_Amount__c ) + getDoubleOrZero( aForecast.Submanager_Modified_Contract__c );
            } else {
                overrideForecast.Manager_Modified_Contract_Rollup__c += aForecast.Contract_Value_Override__c;
            }
            
            if(aForecast.Deal_Forecast_Override__c == NULL) {
                overrideForecast.Manager_Modified_Deal__c += getDoubleOrZero( aForecast.Raw_Quota_Forecast_Rollup__c ) + getDoubleOrZero(aForecast.Submanager_Modified_Deal__c);
            }
            else{
                overrideForecast.Manager_Modified_Deal__c += aForecast.Deal_Forecast_Override__c;
            }
            if(aForecast.Opp_Forecast_Override__c == NULL) {
                overrideForecast.Manager_Modified_Opp__c += getDoubleOrZero( aForecast.Raw_Revenue_Forecast_Rollup__c ) + getDoubleOrZero(aForecast.Submanager_Modified_Opp__c);
            }
            else{
                overrideForecast.Manager_Modified_Opp__c += aForecast.Opp_Forecast_Override__c;
            }
            
            if(aForecast.Deal_Forecast_Amount_Override__c == NULL){
                overrideForecast.Manager_Modified_Deal_Forecast__c += getDoubleOrZero( aForecast.Total_Deal_Forecast__c) + getDoubleOrZero(aForecast.Submanager_Modified_Deal_Forecast__c);
            }
            else{
                overrideForecast.Manager_Modified_Deal_Forecast__c += aForecast.Deal_Forecast_Amount_Override__c;
            }
            
            if(aForecast.Booking_Forecast_Override__c == NULL){
                overrideForecast.Manager_Modified_Booking__c += getDoubleOrZero(aForecast.Total_Bookings_Forecast__c) + getDoubleOrZero(aForecast.Submanager_Modified_Booking__c);
            }
            else{
                overrideForecast.Manager_Modified_Booking__c += aForecast.Booking_Forecast_Override__c;
            }
            
            if(aForecast.eARR_Override__c == NULL){
                overrideForecast.Manager_Modified_eARR__c += getDoubleOrZero(aForecast.Total_eARR__c) + getDoubleOrZero(aForecast.Submanager_Modified_eARR__c);
            }
            else{
                overrideForecast.Manager_Modified_eARR__c += aForecast.eARR_Override__c;
            }
            
            if(aForecast.Booking_eARR_Override__c == NULL){
                overrideForecast.Manager_Modified_Booking_eARR__c += getDoubleOrZero(aForecast.Total_Booking_eARR__c) + getDoubleOrZero(aForecast.Submanager_Modified_Booking_eARR__c);
            }
            else{
                overrideForecast.Manager_Modified_Booking_eARR__c += aForecast.Booking_eARR_Override__c;
            }
            
            if(aForecast.Deal_eARR_Override__c == NULL){
                overrideForecast.Manager_Modified_Deal_eARR__c += getDoubleOrZero(aForecast.Total_Deal_eARR__c) + getDoubleOrZero(aForecast.Submanager_Modified_Deal_eARR__c);
            }
            else{
                overrideForecast.Manager_Modified_Deal_eARR__c += aForecast.Deal_eARR_Override__c;
            }
            
            if(aForecast.Booking_Deal_Override__c == NULL){
                overrideForecast.Manager_Modified_Booking_Deal__c += getDoubleOrZero(aForecast.Total_Booking_Deal__c) + getDoubleOrZero(aForecast.Submanager_Modified_Booking_Deal__c);
            }
            else{
                overrideForecast.Manager_Modified_Booking_Deal__c += aForecast.Booking_Deal_Override__c;
            }
            
            if(aForecast.Booking_Deal_eARR_Override__c == NULL){
                overrideForecast.Manager_Modified_Booking_Deal_eARR__c += getDoubleOrZero(aForecast.Total_Booking_Deal_eARR__c) + getDoubleOrZero(aForecast.Submanager_Modified_Booking_Deal_eARR__c);
            }
            else{
                overrideForecast.Manager_Modified_Booking_Deal_eARR__c += aForecast.Booking_Deal_eARR_Override__c;
            }
        }
        
        try {
            update overrideForecastsMap.values();
        }
        catch( System.DmlException ex ) {
            Map<Id, List<Field_Sales_Forecast__c>> forecastsByManagerForecast = new Map<Id, List<Field_Sales_Forecast__c>>();
            for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
                if( !forecastsByManagerForecast.containsKey( aForecast.Override_Forecast__c ) ) {
                    forecastsByManagerForecast.put( aForecast.Override_Forecast__c, new List<Field_Sales_Forecast__c>() );
                }
                forecastsByManagerForecast.get( aForecast.Override_Forecast__c ).add( aForecast );
            }
            
            for( Integer index = 0; index < ex.getNumDml(); index++ ) {
                Id errorId = overrideForecastsMap.values()[ ex.getDmlIndex(index) ].Id;
                for( Field_Sales_Forecast__c aForecast : forecastsByManagerForecast.get(errorId) ) {
                    aForecast.addError( ex.getDmlMessage(index) );
                }
            }
        }
    }
    
    // Field_Sales_Forecast__c: push values to Manager forecast record
    public static void updateManagerForecasts( List<Field_Sales_Forecast__c> incomingForecasts ) {
        Map<Id, Field_Sales_Forecast__c> managerForecastsMap = new Map<Id, Field_Sales_Forecast__c>();
        for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
            if( !String.isBlank( aForecast.Manager_Forecast__c )
               && !managerForecastsMap.containsKey( aForecast.Manager_Forecast__c ) ) {
                   Field_Sales_Forecast__c managerForecast = new Field_Sales_Forecast__c();
                   managerForecast.Id = aForecast.Manager_Forecast__c;
                   managerForecast.Submanager_Forecast_Total__c = 0.0;
                   managerForecast.Submanager_Contract_Total__c = 0.0;
                   managerForecast.Submanager_Opp_Total__c = 0.0;
                   managerForecast.Submanager_Deal_Total__c = 0.0;
                   managerForecast.Submanager_Modified_Forecast__c = 0.0;
                   managerForecast.Submanager_Modified_Contract__c = 0.0;
                   managerForecast.Submanager_Modified_Deal__c = 0.0;
                   managerForecast.Submanager_Modified_Opp__c = 0.0;
                   managerForecast.Submanager_Modified_Deal_Forecast__c = 0.0;
                   managerForecast.Submanager_Sales_Current_Quarter__c = 0.0;
                   managerForecast.Submanager_Modified_Previous_Quarter__c = 0.0;
                   managerForecast.Submanager_Modified_Booking__c = 0.0;
                   managerForecast.Submanager_Deal_Forecast_Total__c = 0.0;
                   managerForecast.Submanager_Booking_Total__c = 0.0;
                   managerForecast.Submanager_eARR_Total__c = 0.0;
                   managerForecast.Submanager_Booking_eARR_Total__c = 0.0;
                   managerForecast.Submanager_Modified_Booking_eARR__c = 0.0;
                   managerForecast.Submanager_Modified_eARR__c = 0.0;
                   managerForecast.Submanager_Modified_Deal_eARR__c = 0.0;
                   managerForecast.Submanager_Modified_Booking_Deal__c = 0.0;
                   managerForecast.Submanager_Modified_Booking_Deal_eARR__c = 0.0;
                   managerForecast.Submanager_Deal_eARR_Total__c = 0.0;
                   managerForecast.Submanager_Booking_Deal_Total__c = 0.0;
                   managerForecast.Submanager_Booking_Deal_eARR_Total__c = 0.0;
                   managerForecastsMap.put( aForecast.Manager_Forecast__c, managerForecast );
               }
        }
        
        if(managerForecastsMap.isEmpty()) return;
        for( Field_Sales_Forecast__c aForecast : [ SELECT Stage__c, Manager_Forecast__c, Contract_Value_Amount__c,
                                                  Sales_Forecast_Amount__c, Sales_Forecast_Override__c,
                                                  Contract_Value_Override__c, Submanager_Contract_Total__c,
                                                  Submanager_Forecast_Total__c, Submanager_Modified_Contract__c,
                                                  Submanager_Modified_Forecast__c, Sales_Current_Quarter__c,
                                                  Submanager_Sales_Current_Quarter__c, Sales_Forecast_Previous_Quarter_Override__c,
                                                  Submanager_Opp_Total__c,Raw_Revenue_Forecast_Rollup__c, Submanager_Deal_Total__c,
                                                  Raw_Quota_Forecast_Rollup__c, Deal_Forecast_Override__c, Opp_Forecast_Override__c,
                                                  Submanager_Modified_Deal__c, Submanager_Modified_Opp__c, Total_Deal_Forecast__c,
                                                  Submanager_Deal_Forecast_Total__c, Deal_Forecast_Amount_Override__c, Submanager_Modified_Deal_Forecast__c,
                                                  Booking_Forecast_Override__c, Total_Bookings_Forecast__c, Submanager_Booking_Total__c, Submanager_Modified_Booking__c,
                                                  Total_eARR__c, Total_Booking_eARR__c, Booking_eARR_Override__c, eARR_Override__c, Submanager_Booking_eARR_Total__c, Submanager_eARR_Total__c,
                                                  Submanager_Modified_Booking_eARR__c, Submanager_Modified_eARR__c, Submanager_Modified_Deal_eARR__c, Submanager_Modified_Booking_Deal__c,
                                                  Submanager_Modified_Booking_Deal_eARR__c, Deal_eARR_Override__c, Booking_Deal_Override__c, Booking_Deal_eARR_Override__c,
                                                  Total_Deal_eARR__c, Total_Booking_Deal__c, Total_Booking_Deal_eARR__c, Submanager_Deal_eARR_Total__c, Submanager_Booking_Deal_Total__c,
                                                  Submanager_Booking_Deal_eARR_Total__c
                                                  FROM Field_Sales_Forecast__c
                                                  WHERE Manager_Forecast__c IN :managerForecastsMap.keySet() ] ) {
                                                      Field_Sales_Forecast__c relatedForecast = managerForecastsMap.get( aForecast.Manager_Forecast__c );
                                                      relatedForecast.Submanager_Forecast_Total__c += getDoubleOrZero( aForecast.Sales_Forecast_Amount__c ) + getDoubleOrZero( aForecast.Submanager_Forecast_Total__c );
                                                      relatedForecast.Submanager_Contract_Total__c += getDoubleOrZero( aForecast.Contract_Value_Amount__c ) + getDoubleOrZero( aForecast.Submanager_Contract_Total__c );
                                                      relatedForecast.Submanager_Sales_Current_Quarter__c += getDoubleOrZero( aForecast.Sales_Current_Quarter__c ) + getDoubleOrZero( aForecast.Submanager_Sales_Current_Quarter__c );
                                                      relatedForecast.Submanager_Opp_Total__c += getDoubleOrZero(aForecast.Raw_Revenue_Forecast_Rollup__c) + getDoubleOrZero(aForecast.Submanager_Opp_Total__c);
                                                      relatedForecast.Submanager_Deal_Total__c += getDoubleOrZero(aForecast.Raw_Quota_Forecast_Rollup__c) + getDoubleOrZero(aForecast.Submanager_Deal_Total__c);
                                                      relatedForecast.Submanager_Deal_Forecast_Total__c += getDoubleOrZero(aForecast.Total_Deal_Forecast__c) + getDoubleOrZero(aForecast.Submanager_Deal_Forecast_Total__c);
                                                      relatedForecast.Submanager_Booking_Total__c += getDoubleOrZero(aForecast.Total_Bookings_Forecast__c) + getDoubleOrZero(aForecast.Submanager_Booking_Total__c);
                                                      relatedForecast.Submanager_Deal_eARR_Total__c += getDoubleOrZero(aForecast.Total_Deal_eARR__c) + getDoubleOrZero(aForecast.Submanager_Deal_eARR_Total__c);
                                                      relatedForecast.Submanager_Booking_Deal_Total__c += getDoubleOrZero(aForecast.Total_Booking_Deal__c) + getDoubleOrZero(aForecast.Submanager_Booking_Deal_Total__c);
                                                      relatedForecast.Submanager_Booking_Deal_eARR_Total__c += getDoubleOrZero(aForecast.Total_Booking_Deal_eARR__c) + getDoubleOrZero(aForecast.Submanager_Booking_Deal_eARR_Total__c);
                                                      relatedForecast.Submanager_eARR_Total__c += getDoubleOrZero(aForecast.Total_eARR__c) + getDoubleOrZero(aForecast.Submanager_eARR_Total__c);
                                                      relatedForecast.Submanager_Booking_eARR_Total__c += getDoubleOrZero(aForecast.Total_Booking_eARR__c) + getDoubleOrZero(aForecast.Submanager_Booking_eARR_Total__c);
                                                      if( aForecast.Stage__c == 'Closed' ) {
                                                          if( aForecast.Sales_Forecast_Override__c == NULL ) {
                                                              relatedForecast.Submanager_Modified_Forecast__c += getDoubleOrZero( aForecast.Sales_Current_Quarter__c ) + getDoubleOrZero( aForecast.Submanager_Sales_Current_Quarter__c );
                                                          } else {
                                                              relatedForecast.Submanager_Modified_Forecast__c += aForecast.Sales_Forecast_Override__c;
                                                          }
                                                          if( aForecast.Sales_Forecast_Previous_Quarter_Override__c == NULL ) {
                                                              Decimal salesPreviousQuarter = getDoubleOrZero( aForecast.Sales_Forecast_Amount__c ) + getDoubleOrZero( aForecast.Submanager_Forecast_Total__c )
                                                                  - getDoubleOrZero( aForecast.Sales_Current_Quarter__c ) - getDoubleOrZero( aForecast.Submanager_Sales_Current_Quarter__c );
                                                              relatedForecast.Submanager_Modified_Forecast__c += salesPreviousQuarter;
                                                              relatedForecast.Submanager_Modified_Previous_Quarter__c += salesPreviousQuarter;
                                                          } else {
                                                              relatedForecast.Submanager_Modified_Forecast__c += aForecast.Sales_Forecast_Previous_Quarter_Override__c;
                                                              relatedForecast.Submanager_Modified_Previous_Quarter__c += aForecast.Sales_Forecast_Previous_Quarter_Override__C;
                                                          }
                                                      } else {
                                                          if( aForecast.Sales_Forecast_Override__c == NULL ) {
                                                              relatedForecast.Submanager_Modified_Forecast__c += getDoubleOrZero( aForecast.Sales_Forecast_Amount__c ) + getDoubleOrZero( aForecast.Submanager_Modified_Forecast__c );
                                                          } else {
                                                              relatedForecast.Submanager_Modified_Forecast__c += aForecast.Sales_Forecast_Override__c;
                                                          }
                                                      }
                                                      
                                                      if( aForecast.Contract_Value_Override__c == NULL ) {
                                                          relatedForecast.Submanager_Modified_Contract__c += getDoubleOrZero(aForecast.Contract_Value_Amount__c) + getDoubleOrZero( aForecast.Submanager_Modified_Contract__c );
                                                      } else {
                                                          relatedForecast.Submanager_Modified_Contract__c += aForecast.Contract_Value_Override__c;
                                                      }
                                                      
                                                      if( aForecast.Deal_Forecast_Override__c == NULL) {
                                                          relatedForecast.Submanager_Modified_Deal__c += getDoubleOrZero(aForecast.Raw_Quota_Forecast_Rollup__c) + getDoubleOrZero(aForecast.Submanager_Modified_Deal__c);
                                                      }
                                                      else{
                                                          relatedForecast.Submanager_Modified_Deal__c += aForecast.Deal_Forecast_Override__c;
                                                      }
                                                      
                                                      if( aForecast.Opp_Forecast_Override__c == NULL){
                                                          relatedForecast.Submanager_Modified_Opp__c += getDoubleOrZero(aForecast.Raw_Revenue_Forecast_Rollup__c) + getDoubleOrZero(aForecast.Submanager_Modified_Opp__c);
                                                      }
                                                      else{
                                                          relatedForecast.Submanager_Modified_Opp__c += aForecast.Opp_Forecast_Override__c;
                                                      }
                                                      
                                                      if( aForecast.Deal_Forecast_Amount_Override__c == NULL){
                                                          relatedForecast.Submanager_Modified_Deal_Forecast__c += getDoubleOrZero(aForecast.Total_Deal_Forecast__c) + getDoubleOrZero(aForecast.Submanager_Modified_Deal_Forecast__c);
                                                      }
                                                      else{
                                                          relatedForecast.Submanager_Modified_Deal_Forecast__c += aForecast.Deal_Forecast_Amount_Override__c;
                                                      }
                                                      
                                                      if( aForecast.Booking_Forecast_Override__c == NULL){
                                                          relatedForecast.Submanager_Modified_Booking__c += getDoubleOrZero(aForecast.Total_Bookings_Forecast__c) + getDoubleOrZero(aForecast.Submanager_Modified_Booking__c); 
                                                      }
                                                      else{
                                                          relatedForecast.Submanager_Modified_Booking__c += aForecast.Booking_Forecast_Override__c;
                                                      }
                                                      if( aForecast.eARR_Override__c == NULL){
                                                          relatedForecast.Submanager_Modified_eARR__c += getDoubleOrZero(aForecast.Total_eARR__c) + getDoubleOrZero(aForecast.Submanager_Modified_eARR__c); 
                                                      }
                                                      else{
                                                          relatedForecast.Submanager_Modified_eARR__c += aForecast.eARR_Override__c;
                                                      }
                                                      if( aForecast.Booking_eARR_Override__c == NULL){
                                                          relatedForecast.Submanager_Modified_Booking_eARR__c += getDoubleOrZero(aForecast.Total_Booking_eARR__c) + getDoubleOrZero(aForecast.Submanager_Modified_Booking_eARR__c); 
                                                      }
                                                      else{
                                                          relatedForecast.Submanager_Modified_Booking_eARR__c += aForecast.Booking_eARR_Override__c;
                                                      }
                                                      if( aForecast.Deal_eARR_Override__c == NULL){
                                                          relatedForecast.Submanager_Modified_Deal_eARR__c += getDoubleOrZero(aForecast.Total_Deal_eARR__c) + getDoubleOrZero(aForecast.Submanager_Modified_Deal_eARR__c); 
                                                      }
                                                      else{
                                                          relatedForecast.Submanager_Modified_Deal_eARR__c += aForecast.Deal_eARR_Override__c;
                                                      }
                                                      if( aForecast.Booking_Deal_Override__c == NULL){
                                                          relatedForecast.Submanager_Modified_Booking_Deal__c += getDoubleOrZero(aForecast.Total_Booking_Deal__c) + getDoubleOrZero(aForecast.Submanager_Modified_Booking_Deal__c); 
                                                      }
                                                      else{
                                                          relatedForecast.Submanager_Modified_Booking_Deal__c += aForecast.Booking_Deal_Override__c;
                                                      }
                                                      if( aForecast.Booking_Deal_eARR_Override__c == NULL){
                                                          relatedForecast.Submanager_Modified_Booking_Deal_eARR__c += getDoubleOrZero(aForecast.Total_Booking_Deal_eARR__c) + getDoubleOrZero(aForecast.Submanager_Modified_Booking_Deal_eARR__c); 
                                                      }
                                                      else{
                                                          relatedForecast.Submanager_Modified_Booking_Deal_eARR__c += aForecast.Booking_Deal_eARR_Override__c;
                                                      }
                                                  }
        
        try {
            update managerForecastsMap.values();
        }
        catch( System.DmlException ex ) {
            /*Map<Id, List<Field_Sales_Forecast__c>> managerForecastToSubmanagers = new Map<Id, List<Field_Sales_Forecast__c>>();
for( Field_Sales_Forecast__c aForecast : incomingForecasts ) {
if( !managerForecastToSubmanagers.containsKey( aForecast.Manager_Forecast__c ) ) {
managerForecastToSubmanagers.put( aForecast.Manager_Forecast__c, new List<Field_Sales_Forecast__c>() );
}
managerForecastToSubmanagers.get( aForecast.Manager_Forecast__c ).add( aForecast );
}

for( Integer index = 0; index < ex.getNumDml(); index++ ) {
Id errorId = managerForecastsMap.values()[ ex.getDmlIndex(index) ].Id;
for( Field_Sales_Forecast__c aForecast : managerForecastToSubmanagers.get( errorId ) ) {
aForecast.addError( ex.getDmlMessage( index ) );
}
}*/
        }
    }
    
    @future(callout=false)
    public static void futureUpdateRollupForecasts( Set<Id> incomingForecasts ) {
        List<Field_Sales_Forecast__c> forecasts = [ SELECT Id, Manager_Forecast__c, Override_Forecast__c
                                                   FROM Field_Sales_Forecast__c WHERE Id IN :incomingForecasts ];
        updateManagerForecasts( forecasts );
        updateOverrideForecasts( forecasts );
    }
    
    private static String generateForecastKey( Date startDate, Id ownerId, String stage) {
        return startDate.format() + ownerId + stage;
    }
    
    // used when relating sales forecasts to manager forecasts, since stage is irrelevant
    private static String generateForecastKey( Date startDate, Id ownerId ) {
        return startDate.format() + ownerId;
    }
    
    private static Date getClosestQuarterStart( Date someDate ) {
        return Date.newInstance( someDate.year(), (someDate.month()-1) / 3 * 3 + 1, 1 );
    }
    
    private static Decimal getDoubleOrZero( Decimal incoming ) {
        return incoming == NULL ? 0.0 : incoming;
    }
}