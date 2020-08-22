public class ProductUsageService {

    // Create Product Usage by Month records for the given Product Schedule records
    //
    // Query back related AccountSIDs with Twilio Usages using Product_Schedule__c.Forecast_Schedule__r.Opportunity__c to get oppIds.
    // Using the returned opportunities query Opp_SID_SKUs, e.g. [SELECT Account_SID__c FROM Opp_SID_SKUs WHERE Opportunity__c =: oppIds]
    // Map from Product_Schedule__c to List<Account_SID__c>, basically we should know which AccountSIDs related to Product_Schedule__c's Opp
    // Compare Product_Schedule__c.Start_Date__c.month() and year() with Usage.Month__c and Usage.Year__c, and for matches, create a new Object
    //   called Product_Usage_By_Month__c and set Product_Schedule__c and Twilio_Usage__c
    public static List<Product_Usage_By_Month__c> createProductUsageByMonthRecords(List<Product_Schedule__c> productSchedules) {
        List<Product_Usage_By_Month__c> productUsages = new List<Product_Usage_By_Month__c>();

        // Return an empty list if no product schedule records were given
        if (productSchedules == null || productSchedules.isEmpty()) {
            System.debug('ProductUsageService.createProductUsageByMonthRecords() - Product Schedules Empty');
            return productUsages;
        }

        // Get the Opportunity IDs related to the product schedule records
        Map<Product_Schedule__c,Id> prodSchedToOppIdMap = new Map<Product_Schedule__c,Id>();
        for (Product_Schedule__c s : [
            SELECT Id, Forecast_Schedule__r.Start_Date__c, Forecast_Schedule__r.Opportunity__c
            FROM Product_Schedule__c
            WHERE Id IN :productSchedules
        ]) {
            prodSchedToOppIdMap.put(s, s.Forecast_Schedule__r.Opportunity__c);
        }
        
        // Get the SID SKUs for the Opportunities
        Set<Id> oppIds = new Set<Id>(prodSchedToOppIdMap.values());
        System.debug('ProductUsageService.createProductUsageByMonthRecords() - Opportunity ID List: ' + oppIds);
        
        List<Opp_SID_SKU__c> oppSidSkus = [ SELECT Opportunity__c, Account_SID__c FROM Opp_SID_SKU__c WHERE Opportunity__c =: oppIds ];
        System.debug('ProductUsageService.createProductUsageByMonthRecords() - Opportunity SID SKU List: ' + oppSidSkus);

        // Build a map of Product Schedules to Account SIDs
        Map<Product_Schedule__c, Set<Id>> prodSchedToAccountSidMap = new Map<Product_Schedule__c, Set<Id>>();
        Set<Id> allAccountSids = new Set<Id>();
        for (Opp_SID_SKU__c rec : oppSidSkus) {
            for (Product_Schedule__c s : prodSchedToOppIdMap.keySet()) {
                if (prodSchedToOppIdMap.get(s) == rec.Opportunity__c) {
                    Set<Id> sidSet = prodSchedToAccountSidMap.containsKey(s) ? prodSchedToAccountSidMap.get(s) : new Set<Id>();
                    sidSet.add(rec.Account_SID__c);
                    allAccountSids.add(rec.Account_SID__c);
                    prodSchedToAccountSidMap.put(s, sidSet);
                }
            }
        }
        System.debug('ProductUsageService.createProductUsageByMonthRecords() - Product Schedule To Account SID Map: ' + prodSchedToAccountSidMap);
        
        Set<String> uniqueKey = new Set<String>();
        for(Product_Usage_By_Month__c usage: [SELECT Product_Schedule__c, Twilio_Usage__c FROM Product_Usage_By_Month__c 
                                              WHERE Product_Schedule__c =: prodSchedToAccountSidMap.keySet()
                                              AND Twilio_Usage__r.Related_Account_SID__c =: allAccountSids]){
             uniqueKey.add(usage.Product_Schedule__c + '-' + usage.Twilio_Usage__c);                                         
        }
        // Compare Product_Schedule__c.Start_Date__c.month() and year() to Twilio_Usage.Month__c and Twilio_Usage.Year__c.
        // If there is a match, create a new Product_Usage_By_Month__c record, and set Product_Schedule__c and Twilio_Usage__c
        for (Twilio_Usage__c u : [
            SELECT Id, Related_Account_SID__c, Month__c, Year__c
            FROM Twilio_Usage__c
            WHERE Related_Account_SID__c IN :allAccountSids
        ]) {
            for (Product_Schedule__c s : prodSchedToAccountSidMap.keySet()) {
                if (prodSchedToAccountSidMap.get(s).contains(u.Related_Account_SID__c)) {
                    String key = s.Id + '-' + u.Id;
                    if (s.Forecast_Schedule__r.Start_Date__c.month() == u.Month__c && s.Forecast_Schedule__r.Start_Date__c.year() == u.Year__c && !uniqueKey.contains(key)) {
                        // Create Product_Usage_By_Month__c record
                        Product_Usage_By_Month__c rec = new Product_Usage_By_Month__c(
                            Product_Schedule__c = s.Id,
                            Twilio_Usage__c = u.Id
                        );
                        System.debug('ProductUsageService.createProductUsageByMonthRecords() - New Product_Usage_By_Month__c record: ' + rec);
                        productUsages.add(rec);
                        uniqueKey.add(key);
                    }
                }
            }
        }
        insert productUsages;   
        System.debug('ProductUsageService.createProductUsageByMonthRecords() - Created Product_Usage_By_Month__c records: ' + productUsages);

        return productUsages;
    }

    public static Map<Id,Product_Schedule__c> summarizeProductUsages(List<Product_Usage_By_Month__c> productUsageByMonth) {
        // Get all of the Product_Usage_By_Month__c records related Product_Schedule__c records to
        // requery for only the set of records that have a product matching a setting
        Set<Id> productScheduleIds = new Set<Id>();
        Set<Id> twilioUsageIds = new Set<Id>();
        Map<String, String> productsToSummarize = new Map<String,String>();
        for (Product_Usage_By_Month__c u : productUsageByMonth) {
            productScheduleIds.add(u.Product_Schedule__c);
            twilioUsageIds.add(u.Twilio_Usage__c);
			
			if (u.Usage_API_Field__c != null) {
            	productsToSummarize.put(u.Usage_API_Field__c, u.Usage_API_Field__c);
			}
        }
        System.debug('ProductUsageService.summarizeProductUsages() - productScheduleIds: ' + productScheduleIds);
        System.debug('ProductUsageService.summarizeProductUsages() - twilioUsageIds: ' + twilioUsageIds);

        Map<Id,Product_Schedule__c> productScheduleMap = new Map<Id,Product_Schedule__c>([
            SELECT Id, Opportunity_Product__r.Product_Name__c, Actual_Usage__c
            FROM Product_Schedule__c
            WHERE Id = :productScheduleIds
        ]);

        // Get the setting AccountSID_to_SKU_Mappings__c's Product_Name__c to Usage_Field__c mapping for
		// use in Twilio_Usage_c query.
        for (AccountSID_to_SKU_Mappings__c setting : AccountSID_to_SKU_Mappings__c.getAll().values()) {
            if(setting.Year__c == 2018 && !setting.SendGrid_Product__c){
                productsToSummarize.put(setting.Product_Name__c, setting.Usage_Field__c);
            }
        }
        System.debug('ProductUsageService.summarizeProductUsages() - productsToSummarize: ' + productsToSummarize);

        // Query all of the Twilio_Usage__c records related to teh Product_Usage_By_Month__c
        // with having all of the values for Product_Name__c corresponding Usage_Field__c
        // From the setting get the Product_Name__c and corresponding Usage_Field__c that are to summarize
        String fields = String.join(productsToSummarize.values(), ', ');
        String queryString = 'SELECT ' + fields + ' FROM Twilio_Usage__c WHERE Id IN :twilioUsageIds';
        System.debug('ProductUsageService.summarizeProductUsages() - SOQL for twilioUsageMap: ' + queryString);
        Map<Id,Twilio_Usage__c> twilioUsageMap = new Map<Id,Twilio_Usage__c>();
        twilioUsageMap.putAll((List<Twilio_Usage__c>)Database.query(queryString));
        
        // Zero out the Product_Schedule__c.Actual_Usage__c
        for (Product_Schedule__c s : productScheduleMap.values()) {
            System.debug('ProductUsageService.summarizeProductUsages() - Reset Product_Schedule__c (' + s.Id + ') Actual_Usage__c: ' + s.Actual_Usage__c);
			s.Actual_Usage__c = 0;
		}
        
        // Calculate Product_Schedule.Actual_Usage__c based on summing the related Twilio_Usage__c records
        for (Product_Usage_By_Month__c u : productUsageByMonth) {
            System.debug('ProductUsageService.summarizeProductUsages() - Summarizing productUsageByMonth: ' + u);
                
            if (productScheduleMap.containsKey(u.Product_Schedule__c) && twilioUsageMap.containsKey(u.Twilio_Usage__c)) {
                Product_Schedule__c productSchedule = productScheduleMap.get(u.Product_Schedule__c);
                Twilio_Usage__c twilioUsage = twilioUsageMap.get(u.Twilio_Usage__c);
                System.debug('ProductUsageService.summarizeProductUsages() - Summarizing productSchedule: ' + productSchedule);
                System.debug('ProductUsageService.summarizeProductUsages() - Summarizing twilioUsage: ' + twilioUsage);
                
                if (u.Usage_API_Field__c != null) {
                    String usageField = productsToSummarize.get(u.Usage_API_Field__c);
                    System.debug('ProductUsageService.summarizeProductUsages() - Using Product_Usage_By_Month__c.Usage_API_Field__c');
                    System.debug('ProductUsageService.summarizeProductUsages() - Updating Actual_Usage__c using Twilio_Usage__c field: ' + usageField);
                    System.debug('ProductUsageService.summarizeProductUsages() - Update Actual_Usage__c (before): ' + twilioUsage.get(usageField));
                    productSchedule.Actual_Usage__c += twilioUsage.get(usageField) == null ? 0.0 : (Decimal)twilioUsage.get(usageField);
                    productScheduleMap.put(productSchedule.Id, productSchedule);
                    System.debug('ProductUsageService.summarizeProductUsages() - Update Actual_Usage__c (after): ' + productSchedule.Actual_Usage__c);
                } else if (productsToSummarize.containsKey(productSchedule.Opportunity_Product__r.Product_Name__c)) {
                    String usageField = productsToSummarize.get(productSchedule.Opportunity_Product__r.Product_Name__c);
                    System.debug('ProductUsageService.summarizeProductUsages() - Using AccountSID_to_SKU_Mappings__c.Usage_Field__c');
                    System.debug('ProductUsageService.summarizeProductUsages() - Updating Actual_Usage__c using Twilio_Usage__c field: ' + usageField);
                    System.debug('ProductUsageService.summarizeProductUsages() - Update Actual_Usage__c (before): ' + twilioUsage.get(usageField));
                    productSchedule.Actual_Usage__c += twilioUsage.get(usageField) == null ? 0.0 : (Decimal)twilioUsage.get(usageField);
                    productScheduleMap.put(productSchedule.Id, productSchedule);
                    System.debug('ProductUsageService.summarizeProductUsages() - Update Actual_Usage__c (after): ' + productSchedule.Actual_Usage__c);
                }
            }
        }
        update productScheduleMap.values();

        return productScheduleMap;
    }

    public static Map<Id,Product_Schedule__c> rollupActualUsages(List<Product_Usage_By_Month__c> productUsageByMonth) {
        // Get all of the Product_Usage_By_Month__c records related Product_Schedule__c records to
        // requery for only the set of records that have a product matching a setting
        Map<Id,Product_Schedule__c> productScheduleMap = new Map<Id,Product_Schedule__c>();
        for (Product_Usage_By_Month__c u : productUsageByMonth) {
	        // Zero out the Product_Schedule__c.Actual_Usage__c
            productScheduleMap.put(u.Product_Schedule__c, new Product_Schedule__c(Id = u.Product_Schedule__c, Actual_Usage__c = 0));
        }
        System.debug('ProductUsageService.rollupActualUsages() - productScheduleMap: ' + productScheduleMap);

        // Calculate Product_Schedule.Actual_Usage__c based on summing the related Twilio_Usage__c records
        for (Product_Usage_By_Month__c u : [
            SELECT Id, Product_Schedule__c, Actual_Usage__c
            FROM Product_Usage_By_Month__c
            WHERE Product_Schedule__c = :productScheduleMap.keySet()
        ]) {
            System.debug('ProductUsageService.rollupActualUsages() - Summarizing productUsageByMonth: ' + u);
                
            if (productScheduleMap.containsKey(u.Product_Schedule__c)) {
                Product_Schedule__c productSchedule = productScheduleMap.get(u.Product_Schedule__c);
                System.debug('ProductUsageService.rollupActualUsages() - Summarizing productSchedule: ' + productSchedule);
                
                System.debug('ProductUsageService.rollupActualUsages() - Update Actual_Usage__c (before): ' + productSchedule.Actual_Usage__c);
                productSchedule.Actual_Usage__c += u.Actual_Usage__c == null ? 0.0 : u.Actual_Usage__c;
                productScheduleMap.put(productSchedule.Id, productSchedule);
                System.debug('ProductUsageService.rollupActualUsages() - Update Actual_Usage__c (after): ' + productSchedule.Actual_Usage__c);
            }
        }
        update productScheduleMap.values();

        return productScheduleMap;
    }

}