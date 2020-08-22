/******************************************
//Last Modified by: Gram Bischof {01/14/2020}
//
//Description: This is the Controller class used
// in the page OpportunityForecastWidget.
//
//Test Class: OppProductForecastExtTest
//
*******************************************/
public without sharing class OppProductForecastExt {
    public String oppString {get; set;}
    public Id oppId;
    public Boolean isCSMMode {get; set;}
    public String accountSIDMRRString {get; set;}
    public String subProductSizeString {get; set;}
    public Boolean isNewLogo {get; set;}
    public OppProductForecastExt( ApexPages.StandardController standardCont ) {
        oppId = (Id) standardCont.getRecord().Id;
        oppString = JSON.serialize(getOpportunity(oppId));
        isCSMMode = initCSMMode();
        isNewLogo = [SELECT Account.New_Logo_Eligibility__c FROM Opportunity WHERE Id =: oppId].Account.New_Logo_Eligibility__c;
    }
    
    public Boolean initCSMMode(){
        return Opportunity_Forecast_Mode__c.getInstance(UserInfo.getProfileId()).Is_CSM__c;
    }
    
    public String getSendGridSizeMap(){
        Map<String, Set<String>> resultMap = new Map<String, Set<String>>();
        resultMap.put('Essentials', new Set<String>{'40K','100K'});
        resultMap.put('Pro',new Set<String>{'100K','300K','700K','1.5M','2.5M'});
        resultMap.put('Premier (EI)',new Set<String>{'5M','7.5M','10M','15M','20M','25M','50M','100M','200M','300M','400M','500M','600M'});
        resultMap.put('Premier (EASE)',new Set<String>{'5M','7.5M','10M','15M','20M','25M','50M','100M','200M','300M','400M','500M','600M'});
        resultMap.put('Basic', new Set<String>{'5K','10K', '20K', '50K', '100K', '200K', '500K', '1M' , '5M', '10M'});
        resultMap.put('Advanced', new Set<String>{'10K', '20K', '50K', '100K', '200K', '500K', '1M', '5M', '10M'});
        return JSON.serialize(resultMap);
    }
    public String getProductMap(){
        Map<String, Set<String>> resultMap = new Map<String, Set<String>>();
        for(AccountSID_to_SKU_Mappings__c  setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
            if(setting.Sub_Product__c != null && setting.Product_Name__c != null && setting.Year__c == 2018){
                Set<String> subProducts = new Set<String>();
                for(String subProduct: setting.Sub_Product__c.split(';')){
                    subProducts.add(subProduct);
                }
                if(setting.Product_Name__c == 'SendGrid: Expert Services'){
                    subProducts.add('Expert Services - Email Implementation & Strategy');
                    subProducts.add('Expert Services - Marketing Campaigns Migration Service');
                    subProducts.add('Expert Services Change Order');
                    subProducts.add('ISV Expert Partnership (Tier 1)');
                    subProducts.add('ISV Expert Partnership (Tier 2)');
                    subProducts.add('ISV Expert Partnership (Tier 3)');
                }
                if(setting.Product_Name__c == 'SendGrid: Add-Ons'){
                    subProducts.add('Email Testing Credits - 100 Credits');
                    subProducts.add('Email Validation Usage');
                    subProducts.add('250OK Email Analytics');
                }
                resultMap.put(setting.Product_Name__c, subProducts);
            }
        }
        return JSON.serialize(resultMap);
    }
    
    public String getUsageMap(){
        Integer BACK_MONTHS = 1;
        Map<String, List<String>> usageMap = new Map<String, List<String>>();
        
        Set<Id> accountSIds = new Set<Id>();
        for(Opp_SID_SKU__c sku: [SELECT Account_SID__c FROM Opp_SID_SKU__c WHERE Opportunity__c =: oppId]){
            accountSIds.add(sku.Account_SID__c);
        }
        
        Date todaysDate = Date.today().toStartOfMonth();
        Date earliestDate = todaysDate.addMonths(-BACK_MONTHS).toStartOfMonth();
        
        List<String> usageFields = new List<String>();
        for(AccountSID_to_SKU_Mappings__c  setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
            if(setting.Product_Name__c != null && setting.Year__c == 2018 && !setting.SendGrid_Product__c){
                usageFields.add(setting.Usage_Field__c);
            }          
        }
        
        String queryString = 'SELECT Usage_Date__c';
        for(String fieldName: usageFields){
            queryString += ',' + fieldName;
        }
        queryString += ' FROM Twilio_Usage__c WHERE Related_Account_SID__c =: accountSIDs ORDER BY Usage_Date__c';
        List<Twilio_Usage__c> usages = (List<Twilio_Usage__c>) database.query(queryString);
        
        for(Twilio_Usage__c usage: usages){
            
        }
        return JSON.serialize(usageMap);
        
    }
     @TestVisible
     private Boolean inSameQuarter(Date date1, Date date2){
         return getCalendarQuarterString(date1) == getCalendarQuarterString(date2);
     }
     @TestVisible
     private Date toStartOfQuarter(Date dateValue){
         Date resultDate = dateValue;
         switch on dateValue.month(){
             when 1,2,3{
                 resultDate = Date.newInstance(dateValue.year(), 1, 1);
             }
             when 4,5,6{
                 resultDate = Date.newInstance(dateValue.year(), 4, 1);
             }
             when 7,8,9{
                 resultDate = Date.newInstance(dateValue.year(), 7, 1);
             }
             when 10,11,12{
                 resultDate = Date.newInstance(dateValue.year(), 10, 1);
             }
         }
         return resultDate;
     }
     @TestVisible
     private String getCalendarQuarterString(Date dateValue){
         String resultString = String.valueOf(dateValue.year()) + '-';
         switch on dateValue.month(){
             when 1,2,3{
                 resultString += 'Q1';
             }
             when 4,5,6{
                 resultString += 'Q2';
             }
             when 7,8,9{
                 resultString += 'Q3';
             }
             when 10,11,12{
                 resultString += 'Q4';
             }
         }
         return resultString;
     }
     
     public String getMRRMap(){
      Map<String, String> mrrMap = new Map<String, String>();
      Map<String, Map<String, List<String>>> accountSIDMRRMap = new Map<String, Map<String, List<String>>>();
      Map<String, Boolean> mrrSetMap = new Map<String, Boolean>();
      List<String> usageFields = new List<String>();
      String queryString = 'SELECT Account_SID__c,  Opportunity__r.CloseDate, Opp_SID_Added_Date__c ';
      for(AccountSID_to_SKU_Mappings__c  setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
            if(setting.Product_Name__c != null && setting.Year__c == 2018 && !setting.SendGrid_Product__c){
                queryString += ',' + setting.Opp_SKU_Field__c;
                usageFields.add(setting.Usage_Field__c);
                mrrMap.put(setting.Product_Name__c, 'Please Add AccountSID first.');
            }          
      }
      queryString += ' FROM Opp_SID_SKU__c WHERE Opportunity__c =: oppId';
      List<Opp_SID_SKU__c> skus = (List<Opp_SID_SKU__c>) database.query(queryString);
      List<Account_SID_SKU__c> accSKUs = [SELECT Account_SID__c, New_Business_Opportunity__r.StageName, Product_Name__c, Running_Added_Date__c, MRR_Final__c, MRR_Choice__c, MRR_Baseline_Override__c FROM Account_SID_SKU__c WHERE New_Business_Opportunity__c = : oppId];
      Map<String, String> accSKUOverride = new Map<String, String>();
      Boolean stageClosedWon = false;
      for(Account_SID_SKU__c sku: accSKUs){
          if(sku.New_Business_Opportunity__r.StageName == 'Closed Won') stageClosedWon = true;
          String currentMRR = mrrMap.get(sku.Product_Name__c);
          Decimal mrr = currentMRR == null | currentMRR == 'Please Add AccountSID first.' ? 0 : Decimal.valueOf(currentMRR);
          mrr += sku.MRR_Final__c;
          mrrMap.put(sku.Product_Name__c, String.valueOf(mrr));
          mrrSetMap.put(sku.Product_Name__c, true);
          if(sku.MRR_Baseline_Override__c != null) accSKUOverride.put(sku.Account_SID__c + '-' + sku.Product_Name__c, String.valueOf(sku.MRR_Baseline_Override__c));
      }
      Map<Id, Date> accountsidIds = new Map<Id, Date>();
      Map<Id, Date> closeDates = new Map<Id, Date>();
      Set<Integer> years = new Set<Integer>();
      Set<Integer> months = new Set<Integer>();
      Map<String, Decimal> sidMRRMap = new Map<String, Decimal>();
      if(skus != null && !skus.isEmpty()){
          for(AccountSID_to_SKU_Mappings__c  setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
              if(setting.Product_Name__c != null && setting.Year__c == 2018 && !setting.SendGrid_Product__c){
                  for(Opp_SID_SKU__c sku: skus){
                      Decimal mrr = (Decimal) sku.get(setting.Opp_SKU_Field__c);
                      if(mrr == null) mrr = 0;
                      accountsidIds.put(sku.Account_SID__c, sku.Opp_SID_Added_Date__c);
                      closeDates.put(sku.Account_SID__c, sku.Opportunity__r.CloseDate);
                      sidMRRMap.put(sku.Account_SID__c + '-' + setting.Product_Name__c, mrr);
                      months.add(sku.Opp_SID_Added_Date__c.month() == 1 ? 12 : sku.Opp_SID_Added_Date__c.month() - 1);
                      years.add(sku.Opp_SID_Added_Date__c.month() == 1 ? sku.Opp_SID_Added_Date__c.year() - 1: sku.Opp_SID_Added_Date__c.year());
                  }
              }
          }
      }
      Set<Id> ids = accountsidIds.keySet();
      queryString = 'SELECT Name, Account_SID_Friendly_Name1__c, (SELECT Year__c, Month__c ';
      for(String fieldName: usageFields){
          queryString += ',' + fieldName;
      }
      queryString += ' FROM Twilio_Usages__r), (SELECT Launch_Date__c, Product_Name__c, Contract_Length__c FROM Account_SID_SKUs__r WHERE Id !=: accSKUs AND New_Business_Opportunity__r.StageName = \'Closed Won\') FROM Account_SID__c WHERE Id =: ids';
      
      List<Account_SID__c> accSids = (List<Account_SID__c>) database.query(queryString);
      for(AccountSID_to_SKU_Mappings__c  setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
          if(setting.Product_Name__c != null && setting.Year__c == 2018 && !setting.SendGrid_Product__c){
              Decimal totalMrr = 0;
              String usageField = setting.Usage_Field__c;
              for(Account_SID__c accSid: accSids){
                  Date addedDate = accountsidIds.get(accSid.Id);
                  Date closeDate = closeDates.get(accSid.Id);
                  Map<String, List<String>> productMap = accountSIDMRRMap.get(accSid.Name + '-' + accSid.Account_SID_Friendly_Name1__c);
                  if(productMap == null) productMap = new Map<String, List<String>>();
                  Integer month = addedDate.month() == 1 ? 12 : addedDate.month() - 1;
                  Integer year = addedDate.month() == 1 ? addedDate.year() -1 : addedDate.year();
                  Integer lastMonth = month;
                  Integer lastYear = year;
                  if(stageClosedWon && closeDate > Date.newInstance(2020,1,16)){
                     if(!inSameQuarter(addedDate, closeDate)){
                         Date actualDate = addedDate > closeDate ? toStartOfQuarter(addedDate) : toStartOfQuarter(closeDate);
                         lastMonth = actualDate.month() == 1 ? 12 : actualDate.month() - 1;
                         lastYear = actualDate.month() == 1 ? actualDate.year() -1 : actualDate.year();
                     }
                  }
                  else if(!stageClosedWon && !inSameQuarter(addedDate, Date.today())){
                      Date actualDate = addedDate > Date.today() ? toStartOfQuarter(addedDate) : toStartOfQuarter(Date.today());
                      lastMonth = actualDate.month() == 1 ? 12 : actualDate.month() - 1;
                      lastYear = actualDate.month() == 1 ? actualDate.year() -1 : actualDate.year();
                  }
                  Boolean usingLastUsage = false;
                  for(Account_SID_SKU__c accSKU: accsid.Account_SID_SKUs__r){
                      Integer addMonths = accSKU.Contract_Length__c == null || accSKU.Contract_Length__c == 0 ? 1 : Integer.valueOf(accSKU.Contract_Length__c);
                      if(addMonths > 12) addMonths = 12;
                      //lastMonth = accSku.Running_Added_Date__c.month() == 1 ? 12 : accSku.Running_Added_Date__c.month() - 1;
                      //lastYear = accSku.Running_Added_Date__c.month() == 1 ? accSku.Running_Added_Date__c.year() -1 : accSku.Running_Added_Date__c.year();
                      if(accSKU.Product_Name__c == setting.Product_Name__c && addedDate <= accSKU.Launch_Date__c.addMonths(addMonths)){
                          usingLastUsage = true;
                          break;
                      }
                  }
                  List<String> mrrStrings = new List<String>();
                  for(Account_SID_SKU__c accSKU: accSKUs){
                      if(accSKU.Product_Name__c == setting.Product_Name__c){
                         lastMonth = accSku.Running_Added_Date__c.month() == 1 ? 12 : accSku.Running_Added_Date__c.month() - 1;
                         lastYear = accSku.Running_Added_Date__c.month() == 1 ? accSku.Running_Added_Date__c.year() -1 : accSku.Running_Added_Date__c.year();
                      }
                  }
                  Boolean havingLastMonth = false;
                  for(Twilio_Usage__c usage: accSid.Twilio_Usages__r){
                      if(usage.Year__c == lastYear && usage.Month__c == lastMonth){
                          havingLastMonth = true;
                          mrrStrings.add(String.valueOf(usage.get(usageField) == null ? 0 : (Decimal) usage.get(usageField)) + '-' + String.valueOf(usingLastUsage));
                          break;
                      }
                  }
                  if(!havingLastMonth) mrrStrings.add('0-' + String.valueOf(usingLastUsage));
                  mrrStrings.add(String.valueOf(sidMRRMap.get(accSid.Id + '-' + setting.Product_Name__c) == null ? 0 : sidMRRMap.get(accSid.Id + '-' + setting.Product_Name__c)) + '-' + String.valueOf(!usingLastUsage));
                  String overrideValue = accSKUOverride.get(accSid.Id + '-' + setting.Product_Name__c);
                  if(overrideValue != null){
                      mrrStrings.add(overrideValue+'-true');
                      mrrStrings[0] = mrrStrings[0].split('-')[0] + '-false';
                      mrrStrings[1] = mrrStrings[1].split('-')[0] + '-false';
                      totalMrr += Decimal.valueOf(overrideValue);
                  }
                  else{
                      mrrStrings.add('N/A-false');
                      if(usingLastUsage){
                          for(Twilio_Usage__c usage: accSid.Twilio_Usages__r){
                              if(usage.Year__c == lastYear && usage.Month__c == lastMonth){
                                  totalMrr += usage.get(usageField) == null ? 0 : (Decimal) usage.get(usageField);
                              }
                          }
                      }
                      else{
                          totalMrr += sidMRRMap.get(accSid.Id + '-' + setting.Product_Name__c) == null ? 0 : sidMRRMap.get(accSid.Id + '-' + setting.Product_Name__c);
                      }
                  }
                  productMap.put(setting.Product_name__c, mrrStrings);
                 
                  accountSIDMRRMap.put(accSid.Name + '-' + accSid.Account_SID_Friendly_Name1__c, productMap);
              }
              mrrMap.put(setting.Product_Name__c, String.valueOf(totalMrr));
          }
      }
      
      accountSIDMRRString = JSON.serialize(accountSIDMRRMap);
      return JSON.serialize(mrrMap);
      
  }
    public String getSoftwareProductMap(){
        Map<String, Boolean> resultMap = new Map<String, Boolean>();
        for(AccountSID_to_SKU_Mappings__c  setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
            if(setting.Product_Name__c != null && setting.Year__c == 2018){
                resultMap.put(setting.Product_Name__c, setting.Software_Product__c);
            }
        }
        return JSON.serialize(resultMap);
    }
    
    public String getXsellMap(){
        Map<String, Boolean> resultMap = new Map<String, Boolean>();
        Id accid = [SELECT AccountId FROM Opportunity WHERE Id =: oppId].AccountId;
        Map<String, Boolean> xsellDataMap = new Map<String, Boolean>();
        for(Account_X_sells__c xsell: [SELECT Product_Name__c, MRR__c, Eligibility__c FROM Account_X_sells__c WHERE Account__c =: accid]){
            xsellDataMap.put(xsell.Product_Name__c, xsell.Eligibility__c);
        }
        for(AccountSID_to_SKU_Mappings__c  setting: AccountSID_to_SKU_Mappings__c.getAll().values()){
            if(setting.Product_Name__c != null && setting.Year__c == 2018){
                Boolean eligibility = xsellDataMap.get(setting.Product_Name__c) == null ? false: xsellDataMap.get(setting.Product_Name__c);
                resultMap.put(setting.Product_Name__c, eligibility);
            }
        }
        return JSON.serialize(resultMap);
    }
    public String getSubProducts(){
        List<Twilio_Sub_Product__c> subProducts = [SELECT Name, Twilio_Product__r.Product_Name__c, SendGrid_Package_Size__c FROM Twilio_Sub_Product__c WHERE Twilio_Product__r.Opportunity__c =:oppId];
        Map<String, String> sizeMap = new Map<String, String>();
        List<String> productNames = new List<String>();
        for(Twilio_Sub_Product__c subProd : subProducts){
            sizeMap.put(subProd.Twilio_Product__r.Product_Name__c + '-' + subProd.Name, subProd.SendGrid_Package_Size__c);
            if(subProd.Twilio_Product__r.Product_Name__c != 'SendGrid: EASE' && subProd.Twilio_Product__r.Product_Name__c != 'SendGrid: Email Infrastructure' ){
                productNames.add(subProd.Name);
            }
            else{
                if(subProd.Name != 'Custom' && subProd.Name != 'Premier (EASE)' && subProd.Name != 'Premier (EI)')
                    productNames.add(subProd.Twilio_Product__r.Product_Name__c + '-' + subProd.Name);
                else
                    productNames.add(subProd.Name);
            }
        }
        subProductSizeString = JSON.serialize(sizeMap);
        return JSON.serialize(productNames);
    }
    public class MissingInformationException extends System.Exception {}
    @RemoteAction
    public static void saveForecasts(String jsonString, String productJson, String subProductString, Id oppId){
        List<Product_Schedule__c> newForecasts = (List<Product_Schedule__c>) JSON.deserialize(jsonString, List<Product_Schedule__c>.class);
        
        List<Product_Schedule__c> oldForecasts = [SELECT Opportunity_Product__c, Start_Date__c FROM Product_Schedule__c WHERE Opportunity_Product__r.Opportunity__c =:oppId];
        
        List<Opportunity_Product__c> oldProducts = [SELECT Id FROM Opportunity_Product__c WHERE Opportunity__c =:oppId];
        
        List<Opportunity_Product__c> updateProducts = (List<Opportunity_Product__c>) JSON.deserialize(productJson, List<Opportunity_Product__c>.class);
        
        List<Forecast_Schedule__c> oldOppForecasts = [SELECT Start_Date__c FROM Forecast_Schedule__c WHERE Opportunity__c =: oppId];
        
        List<Twilio_Sub_Product__c> updateSubProducts = (List<Twilio_Sub_Product__c>) JSON.deserialize(subProductString, List<Twilio_Sub_Product__c>.class);
        
        List<Twilio_Sub_Product__c> existingSubProducts = [SELECT Name, Twilio_Product__c FROM Twilio_Sub_Product__c WHERE Twilio_Product__r.Opportunity__c = :oppId];
        
        
        //Date startDate = newForecasts[0].Start_Date__c;
        //Date endDate = newForecasts[newForecasts.size() - 1].Start_Date__c;
        //Integer diffMonth = (endDate.year() - startDate.year()) * 12 + (endDate.month() - startDate.month()) + 1;
        
        Map<String, Forecast_Schedule__c> timeToOppForecastMap = new Map<String, Forecast_Schedule__c>();
        
        Set<Id> deleteProducts = new Set<Id>();
        
        for(Opportunity_Product__c prod: oldProducts){
            deleteProducts.add(prod.Id);              
        }
        
        for(Opportunity_Product__c prod: updateProducts){
            if(deleteProducts.contains(prod.Id)){
                deleteProducts.remove(prod.Id);
            }
        }
        
        for(Forecast_Schedule__c schedule: oldOppForecasts){
            schedule.Forecast_Amount__c = 0;
            schedule.CSM_Forecast_Amount__c = 0;
            timeToOppForecastMap.put(String.valueOf(schedule.Start_Date__c.year()) + String.valueOf(schedule.Start_Date__c.month()), schedule);
        }
        
        Set<Id> oppForecastIds = new Set<Id>();
        Set<Id> oppProductIds = new Set<Id>();
        Map<Id, Integer> productMap = new Map<Id, Integer>();
        
        for(Product_Schedule__c prodSchedule: newForecasts){
            if(prodSchedule.Renegotiation_Amount__c == null) prodSchedule.Renegotiation_Amount__c = 0;
            Forecast_Schedule__c oppSchedule = timeToOppForecastMap.get(String.valueOf(prodSchedule.Start_Date__c.year()) + String.valueOf(prodSchedule.Start_Date__c.month()));
            //if(prodSchedule.Name != null && prodSchedule.Name.containsIgnoreCase('SendGrid')){continue;}
            if(oppSchedule != null){
                oppSchedule.Forecast_Amount__c += prodSchedule.New_Business_Forecast_Amount__c - prodSchedule.Renegotiation_Amount__c;
                if(prodSchedule.CSM_Forecast_Amount__c != null)
                    oppSchedule.CSM_Forecast_Amount__c += prodSchedule.CSM_Forecast_Amount__c;
                if(oppSchedule.Id != null){
                    oppForecastIds.add(oppSchedule.Id);
                }
            }
            else{
                oppSchedule = new Forecast_Schedule__c(Opportunity__c = oppId, CSM_Forecast_Amount__c = prodSchedule.CSM_Forecast_Amount__c, Forecast_Amount__c = prodSchedule.New_Business_Forecast_Amount__c - prodSchedule.Renegotiation_Amount__c, Start_Date__c = prodSchedule.Start_Date__c.toStartOfMonth(), End_Date__c = prodSchedule.Start_Date__c.toStartOfMonth().addMonths(1).addDays(-1));
            }
            timeToOppForecastMap.put(String.valueOf(prodSchedule.Start_Date__c.year()) + String.valueOf(prodSchedule.Start_Date__c.month()), oppSchedule);
        }
        
        List<Forecast_Schedule__c> deleteSchedules = new List<Forecast_Schedule__c>();
        for(Forecast_Schedule__c schedule: oldOppForecasts){
            if(!oppForecastIds.contains(schedule.Id)){
                deleteSchedules.add(schedule);
                timeToOppForecastMap.remove(String.valueOf(schedule.Start_Date__c.year()) + String.valueOf(schedule.Start_Date__c.month()));
            }
        }
        Savepoint sp = Database.setSavepoint();
        try{
            
            for(Integer i = oldForecasts.size() - 1; i >= 0; i--){
                for(Product_Schedule__c prodSchedule: newForecasts){
                    if(oldForecasts[i].Id == prodSchedule.Id){
                        oldForecasts.remove(i);
                        break;
                    }
                }
            }
            
            delete oldForecasts;
            delete deleteSchedules;
            upsert timeToOppForecastMap.values();
            
            
            upsert updateProducts;
            
            for(Product_Schedule__c prodSchedule: newForecasts){
                
                Forecast_Schedule__c oppSchedule = timeToOppForecastMap.get(String.valueOf(prodSchedule.Start_Date__c.year()) + String.valueOf(prodSchedule.Start_Date__c.month()));
                if(prodSchedule.Forecast_Schedule__c == null){
                    prodSchedule.Forecast_Schedule__c = oppSchedule.Id;
                }
                
                for(Opportunity_Product__c oppProduct: updateProducts){
                    if(String.valueOf(prodSchedule.Opportunity_Product__c) == String.valueOf(oppProduct.Product_Name__c)){
                        prodSchedule.Opportunity_Product__c = oppProduct.Id;
                        break;
                    }
                }
            }
            
            //system.assert(false, newForecasts);
            upsert newForecasts;
            
            //ProductUsageService.summarizeProductUsages(ProductUsageService.createProductUsageByMonthRecords(newForecasts));
            
            
            
            List<Opportunity_Product__c> deleteOppProducts = new List<Opportunity_Product__c>();
            for(Id deleteProdId: deleteProducts){
                deleteOppProducts.add(new Opportunity_Product__c(Id = deleteProdId));
            }
            
            
            
            for(Twilio_Sub_Product__c subProduct: updateSubProducts){
                for(Opportunity_Product__c oppProduct: updateProducts){
                    if(String.valueOf(subProduct.Twilio_Product__c) == String.valueOf(oppProduct.Product_Name__c)){
                        subProduct.Twilio_Product__c = oppProduct.Id;
                        break;
                    }
                }
            }
            for(Integer j = updateSubProducts.size() - 1; j >= 0 ; j--){
                for(Integer i = existingSubProducts.size() - 1; i >= 0;  i--){
                    if(updateSubProducts[j].Name == existingSubProducts[i].Name && updateSubProducts[j].Twilio_Product__c == existingSubProducts[i].Twilio_Product__c){
                        updateSubProducts[j].Id = existingSubProducts[i].Id;
                        existingSubProducts.remove(i);
                        break;
                    }
                }
            }
            
            upsert updateSubProducts;
            delete existingSubProducts;
            delete deleteOppProducts;
            
            List<Opportunity_Product__c> prods = [SELECT Opportunity__c, (SELECT Id FROM Account_SID_SKUs__r) FROM Opportunity_Product__c WHERE Opportunity__c =: oppId];
            system.debug(prods.size());
            List<Opportunity_Product__c> filteredProds = new List<Opportunity_Product__c>();
            Set<Id> oppIds = new Set<Id>();
            for(Opportunity_Product__c prod: prods){
                if(prod.Account_SID_SKUs__r == null || prod.Account_SID_SKUs__r.isEmpty()){
                    filteredProds.add(prod);
                    oppIds.add(prod.Opportunity__c);
                }
            }
            system.debug(filteredProds.size());
            List<Opportunity> opps = [SELECT Id, (SELECT Account_SID__c FROM Opp_SID_SKUs__r) FROM Opportunity WHERE Id =: oppIds];
            List<Account_SID_SKU__c> insertSkus = new List<Account_SID_SKU__c>();
            for(Opportunity_Product__c oppProd: filteredProds){
                for(Opportunity opp: opps){
                    if(opp.Id == oppProd.Opportunity__c && opp.Opp_SID_SKUs__r != null && !opp.Opp_SID_SKUs__r.isEmpty()){
                        for(Opp_SID_SKU__c sku: opp.Opp_SID_SKUs__r){
                            insertSKUs.add(
                                new Account_SID_SKU__c(Opportunity_Product__c = oppProd.Id, New_Business_Opportunity__c = opp.Id, Opp_SID_SKU__c = sku.Id, Account_SID__c = sku.Account_SID__c)
                            );  
                        }
                    }
                }
            }
            system.debug(insertSKUs.size());
            insert insertSKUs;
        }
        catch(DMLException e){
            Database.rollback(sp);
            throw new MissingInformationException(e.getMessage());
        }
        
        
    }
    
    @RemoteAction
    public static Opportunity getOpportunity( Id opportunityId )
    {
        Opportunity theOpportunity = queryOpportunity( opportunityId );
        
        return theOpportunity;
    }
    
    @RemoteAction
    public static Id addProduct( String productStr, String subProductStr)
    {
        Opportunity_Product__c newProduct = (Opportunity_Product__c) JSON.deserialize(productStr, Opportunity_Product__c.class);
        insert newProduct;
        List<String> subProductNames = (List<String>) JSON.deserialize(subProductStr, List<String>.class);
        List<Twilio_Sub_Product__c> subProducts = new List<Twilio_Sub_Product__c>();
        for(String subProductName: subProductNames){
            subProducts.add(new Twilio_Sub_Product__c(Name = subProductName, Twilio_Product__c = newProduct.Id));
        }
        insert subProducts;
        return newProduct.Id;
    }
    
    private static Opportunity queryOpportunity( Id opportunityId )
    {
        return [ SELECT Id, Name, StageName, Amount, Launch_Date__c, Contract_Terms_Months__c,
                (SELECT Id, Product_Name__c, Software_Product__c, Amount__c, Percent_Off_Baseline__c, Contract_Terms_Months__c, Quote_Amount__c, Renegotiation_Amount__c FROM Opportunity_Products__r)
                FROM Opportunity WHERE Id = :opportunityId ];
    }
    
    public String getProductSchedules(){
        return JSON.serialize([SELECT Id, Forecast_Schedule__c, Opportunity_Product__c, CSM_Forecast_Amount__c, Renegotiation_Amount__c, Opportunity_Product__r.Product_Name__c, New_Business_Forecast_Amount__c, Start_Date__c, End_Date__c FROM Product_Schedule__c WHERE Opportunity_Product__r.Opportunity__c =:oppId]);
    }
    
    public String getProductList(){
        Map<String, Schema.SObjectField> oppFieldMap = Opportunity_Product__c.SObjectType.getDescribe().fields.getMap();
        
        List<String> values = new List<String>();
        List<Schema.PicklistEntry> picklistValues = oppFieldMap.get('Product_Name__c').getDescribe().getPickListValues();
        
        for(Schema.PicklistEntry entry: picklistValues){
            values.add(entry.getValue());
        }
        
        return JSON.serialize(values);
        
    }
}