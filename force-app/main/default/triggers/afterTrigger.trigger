trigger afterTrigger on Partner_Forecast__c (after insert, after update) {
    
    List<Partner_Forecast__c> partnerForecasts = Trigger.new;
    
    // If TCV forecast, update the associated TCV fields on the Oppty
    List<Opportunity> tcvOpps = new List<Opportunity>();
    RecordType tcvType = [SELECT Id, Name FROM RecordType WHERE sobjecttype = 'Partner_Forecast__c' AND developerName ='TCV'];
    
    // If Revenue forecast, create the Forecast breakouts
    RecordType revenueType = [SELECT Id, Name FROM RecordType WHERE sobjecttype = 'Partner_Forecast__c' AND developerName ='Revenue'];
    
    List<Partner_Forecast_Breakout__c> breakouts = new List<Partner_Forecast_Breakout__c>();
    List<Partner_Forecast_Breakout__c> existingBreakouts = new List<Partner_Forecast_Breakout__c>();
    
    //List<String> fiscalPeriods = new List<String>();
    for (Partner_Forecast__c pf : partnerForecasts) {
        if (pf.RecordTypeId== tcvType.Id) {
            // Populate TCV fields on the related Oppty
            Id oppId = pf.Opportunity__c;
            Opportunity o = [SELECT Id, Year_1_Amount__c, Year_2_Amount__c, Year_3_Amount__c, TCV_Amount__c, Estimated_Software_Percentage__c, Estimated_Software_Amount__c FROM Opportunity WHERE Id = :oppId];
            o.Year_1_Amount__c = pf.Year_1_Amount__c;
            o.Year_2_Amount__c = pf.Year_2_Amount__c;
            o.Year_3_Amount__c = pf.Year_3_Amount__c;
            if(pf.Confidence_Level__c == 'Closed') o.Partner_Sales_Bell_Check__c = true;
            o.TCV_Amount__c = pf.Total_Amount__c;
            o.Estimated_Software_Percentage__c = pf.Estimated_Software__c;
            tcvOpps.add(o);
            System.debug('Update TCV Opp');
            
            // Also create breakouts to collect yearly distributions
            existingBreakouts = [SELECT Id, Forecast_Category__c, Amount__c, Partner_Forecast__c FROM Partner_Forecast_Breakout__c WHERE Partner_Forecast__c = :pf.Id];
            if (existingBreakouts.size() > 0) {
                // Update existing breakouts
                for (Partner_Forecast_Breakout__c eb : existingBreakouts) {
                    // Update breakout amounts for each category
                    if (eb.Forecast_Category__c == 'TCV Year 1') 
                        eb.Amount__c = pf.Year_1_Amount__c;
                    else if (eb.Forecast_Category__c == 'TCV Year 2')
                        eb.Amount__c = pf.Year_2_Amount__c;
                    else eb.Amount__c = pf.Year_3_Amount__c;
                    
                    breakouts.add(eb);
                }                
                
            } else {
                // Create new breakouts
                Partner_Forecast_Breakout__c y1 = new Partner_Forecast_Breakout__c();
                y1.Partner_Forecast__c = pf.Id;
                y1.Forecast_Category__c = 'TCV Year 1';
                y1.Amount__c = pf.Year_1_Amount__c;
                Partner_Forecast_Breakout__c y2 = new Partner_Forecast_Breakout__c();
                y2.Partner_Forecast__c = pf.Id;
                y2.Forecast_Category__c = 'TCV Year 2';
                y2.Amount__c = pf.Year_2_Amount__c;
                Partner_Forecast_Breakout__c y3 = new Partner_Forecast_Breakout__c();
                y3.Partner_Forecast__c = pf.Id;
                y3.Forecast_Category__c = 'TCV Year 3';
                y3.Amount__c = pf.Year_3_Amount__c;
                
                breakouts.add(y1);
                breakouts.add(y2);
                breakouts.add(y3);
            }
            
        } else if (pf.RecordTypeId == revenueType.Id) {
            // Create Forecast breakouts (or update existing breakouts)
            existingBreakouts = [SELECT Id, Forecast_Category__c, Amount__c, Partner_Forecast__c FROM Partner_Forecast_Breakout__c WHERE Partner_Forecast__c = :pf.Id];
            if (existingBreakouts.size() < 5) {
                // Create new breakout for 'Closed'
                Partner_Forecast_Breakout__c cl = new Partner_Forecast_Breakout__c();
                cl.Partner_Forecast__c = pf.Id;
                cl.Forecast_Category__c = 'Closed';
                cl.Amount__c = pf.Closed__c;
                cl.Default_Amount__c = pf.Closed__c;
                
                breakouts.add(cl);
            }
            if (existingBreakouts.size() > 0) {
                // Update existing breakouts
                for (Partner_Forecast_Breakout__c eb : existingBreakouts) {
                    // Update breakout amounts for each category
                    if (eb.Forecast_Category__c == 'Closed') {
                        eb.Amount__c = pf.Closed__c;
                        eb.Default_Amount__c = pf.Closed__c;
                    } else if (eb.Forecast_Category__c == 'Commit') {
                        if (pf.Commit__c > pf.Closed__c) {
                            eb.Amount__c = pf.Commit__c - pf.Closed__c;
                        } else eb.Amount__c = 0;
                        eb.Default_Amount__c = pf.Commit__c;
                    } else if (eb.Forecast_Category__c == 'Forecast') {
                        if ((pf.Forecast__c - pf.Commit__c) < 0) 
                            eb.Amount__c = 0;
                        else eb.Amount__c = pf.Forecast__c - pf.Commit__c;
                        eb.Default_Amount__c = pf.Forecast__c;
                    } else if (eb.Forecast_Category__c == 'Best Case') {
                        if ((pf.Best_Case__c - pf.Forecast__c) < 0)
                            eb.Amount__c = 0;
                        else eb.Amount__c = pf.Best_Case__c - pf.Forecast__c;
                        eb.Default_Amount__c = pf.Best_Case__c;
                    } else {
                        if ((pf.Pipeline__c - pf.Best_Case__c) < 0)
                            eb.Amount__c = 0;
                        else eb.Amount__c = pf.Pipeline__c - pf.Best_Case__c;
                        eb.Default_Amount__c = pf.Pipeline__c;
                    }
                    
                    breakouts.add(eb);
                }                
            } else {
                // Create new breakouts
                Partner_Forecast_Breakout__c cl = new Partner_Forecast_Breakout__c();
                cl.Partner_Forecast__c = pf.Id;
                cl.Forecast_Category__c = 'Closed';
                cl.Amount__c = pf.Closed__c;
                cl.Default_Amount__c = pf.Closed__c;
                
                Partner_Forecast_Breakout__c cm = new Partner_Forecast_Breakout__c();
                cm.Partner_Forecast__c = pf.Id;
                cm.Forecast_Category__c = 'Commit';
                cm.Amount__c = pf.Commit__c;
                cm.Default_Amount__c = pf.Commit__c;
                
                Partner_Forecast_Breakout__c fc = new Partner_Forecast_Breakout__c();
                fc.Partner_Forecast__c = pf.Id;
                fc.Forecast_Category__c = 'Forecast';
                if ((pf.Forecast__c - pf.Commit__c) < 0)
                    fc.Amount__c = 0;
                else fc.Amount__c = pf.Forecast__c - pf.Commit__c;
                fc.Default_Amount__c = pf.Forecast__c;
                
                Partner_Forecast_Breakout__c bc = new Partner_Forecast_Breakout__c();
                bc.Partner_Forecast__c = pf.Id;
                bc.Forecast_Category__c = 'Best Case';
                if ((pf.Best_Case__c - pf.Forecast__c) < 0)
                    bc.Amount__c = 0;
                else bc.Amount__c = pf.Best_Case__c - pf.Forecast__c;
                bc.Default_Amount__c = pf.Best_Case__c;
                
                Partner_Forecast_Breakout__c pl = new Partner_Forecast_Breakout__c();
                pl.Partner_Forecast__c = pf.Id;
                pl.Forecast_Category__c = 'Pipeline';
                if ((pf.Pipeline__c - pf.Best_Case__c) < 0)
                    pl.Amount__c = 0;
                else pl.Amount__c = pf.Pipeline__c - pf.Best_Case__c;
                pl.Default_Amount__c = pf.Pipeline__c;
                
                breakouts.add(cl);
                breakouts.add(cm);
                breakouts.add(fc);
                breakouts.add(bc);
                breakouts.add(pl);  
                
                //fiscalPeriods.add(pf.Fiscal_Period_Revenue__c);              
            }
        }
        
    }
    
    // Only trigger an update on Opportunities that were influenced by a partner in the matching fiscal period as the forecast
    /*List<Opportunity> opps = [SELECT Fiscal_Period_Closed__c, Partner_Influencer__c FROM Opportunity WHERE Fiscal_Period_Closed__c IN :fiscalPeriods AND Partner_Influencer__c <> NULL];
    for (Opportunity o : tcvOpps) {
        opps.add(o);
    }
    update opps;*/
    // update or insert, based on whether there are existing breakouts
    upsert breakouts;
    update tcvOpps;
    
}