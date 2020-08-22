public without sharing class WholesaleUsageServices{
  public static Boolean bypassTrigger = false;
  
  public static Map<String, Id> ownerMap{
      get{
          if(ownerMap == null){
              ownerMap = new Map<String, Id>();
              for(Wholesale_Opp_Owner__c setting: Wholesale_Opp_Owner__c.getAll().values()){
                  if(setting.Active__c){
                      ownerMap.put(setting.Managed_By__c, setting.UserId__c);
                  }
              }
          }
          return ownerMap;
      }
      set;
  }
  
  public static Id getOwnerId(String managedBy){
      Id ownerId = ownerMap.get(managedBy);
      if(ownerId == null) ownerId = '00540000003nTrT';
      return ownerId;
  }
  
  public static Map<Decimal, String> monthMap = new Map<Decimal, String>{
        1 => 'January',
        2 => 'February',
        3 => 'March',
        4 => 'April',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'August',
        9 => 'September',
        10 => 'October',
        11 => 'November',
        12 => 'December'
    };
    public static void beforeInsert(List<Wholesale_Usage__c> triggerUsages){
            LeadTriggerHandler.runOnce = true;
            bypassTrigger = true;
            Set<String> ids = new Set<String>();
            for(Wholesale_Usage__c usage: triggerUsages){
                if(usage.Account__c == null && usage.CRM_ID__c != null){
                    ids.add(usage.CRM_ID__c);
                }
            }
            
            Map<String, Account> crmAccountMap = new Map<String, Account>();
            for(Account acc: [SELECT Id,Super_Network_Admin_CRM_ID__c FROM Account WHERE Super_Network_Admin_CRM_ID__c =: ids]){
                crmAccountMap.put(acc.Super_Network_Admin_CRM_ID__c, acc);
            }
            
            List<Account> insertAccounts = new List<Account>();
            for(Wholesale_Usage__c usage: triggerUsages){
                if(usage.Account__c == null){
                    Account acc = crmAccountMap.get(usage.CRM_ID__c);
                    if(acc == null){
                        Account newAcc = new Account(Name = usage.Account_Name__c, RecordTypeId = '012400000009nVm', Type = 'Wholesale', Super_Network_Admin_CRM_ID__c = usage.CRM_ID__c);
                        if(usage.Managed_By__c != null) newAcc.OwnerId =  getOwnerId(usage.Managed_By__c);
                        crmAccountMap.put(usage.CRM_ID__c, newAcc);
                        insertAccounts.add(newAcc);
                    }
                }
            }
            
            insert insertAccounts;
            
            for(Wholesale_Usage__c usage: triggerUsages){
                if(usage.Account__c == null){
                    usage.Account__c = crmAccountMap.get(usage.CRM_ID__c).Id;
                }
            }
            
            Map<Wholesale_Usage__c, String> oppStringMap = new Map<Wholesale_Usage__c, String>();
            Map<String, Opportunity> oppMap = new Map<String, Opportunity>();
            
            Set<Id> accountIds = new Set<Id>();
            for(Wholesale_Usage__c usage: triggerUsages){
                if(usage.Opportunity__c == null){
                    Date newDate = usage.Date__c.addMonths(1).toStartofMonth().addDays(-1);
                    String keyString = usage.Account__c + '-' + newDate.format();
                    accountIds.add(usage.Account__c);
                    oppStringMap.put(usage, keyString);
                }
            }
            
            Date thisYear = Date.newInstance(Date.today().year(), 1, 1);
            for(Opportunity opp: [SELECT AccountId, CloseDate FROM Opportunity WHERE AccountId =:accountIds AND CloseDate >=: thisYear]){
                String keyString = opp.AccountId + '-' + opp.CloseDate.format();
                oppMap.put(keyString, opp);
            }
            
            List<Opportunity> insertOpportunity = new List<Opportunity>();
            for(Wholesale_Usage__c usage: triggerUsages){
                if(usage.Opportunity__c == null){
                    Date newDate = usage.Date__c.addMonths(1).toStartofMonth().addDays(-1);
                    String keyString = usage.Account__c + '-' + newDate.format();
                    String monthString = monthMap.get(newDate.month());
                    Opportunity opp = oppMap.get(keyString);
                    if(opp == null){
                        Opportunity newOpp = new Opportunity(Name = usage.Account_Name__c + ' - ' + monthString, AccountId = usage.Account__c, CloseDate = newDate, StageName = 'Incubate', RecordTypeId = '0121W000000MK5l', Contract_Terms_Months__c = 1);
                        
                        if(usage.Managed_By__c != null) newOpp.OwnerId =  getOwnerId(usage.Managed_By__c);
                        insertOpportunity.add(newOpp);
                        oppMap.put(keyString, newOpp);
                     }
                }
            }
            
            insert insertOpportunity;
            
            Map<Id, List<Wholesale_Usage__c>> oppUsageMaps = new Map<Id, List<Wholesale_Usage__c>>();
            List<Wholesale_Usage__c> updateUsages = new List<Wholesale_Usage__c>();
            for(Wholesale_Usage__c usage: triggerUsages){
                if(usage.Opportunity__c == null){
                    Date newDate = usage.Date__c.addMonths(1).toStartofMonth().addDays(-1);
                    String keyString = usage.Account__c + '-' + newDate.format();
                    usage.Opportunity__c = oppMap.get(keyString).Id;
                    updateUsages.add(usage);
                }
                List<Wholesale_Usage__c> usages = oppUsageMaps.get(usage.Opportunity__c);
                if(usages == null) usages = new List<Wholesale_Usage__c>();
                usages.add(usage);
                oppUsageMaps.put(usage.Opportunity__c, usages);
            }
            
            update updateUsages;
            for(Wholesale_Usage__c usage: [SELECT Date__c, Account__c, Opportunity__c, Revenue_Input__c, Volume__c, margin__c FROM Wholesale_Usage__c WHERE Opportunity__c =: oppUsageMaps.keySet()]){
                List<Wholesale_Usage__c> usages = oppUsageMaps.get(usage.Opportunity__c);
                if(usages == null) usages = new List<Wholesale_Usage__c>();
                usages.add(usage);
                oppUsageMaps.put(usage.Opportunity__c, usages);
            }
            
            List<Opportunity> updateOpps = new List<Opportunity>();
            for(Id oppId: oppUsageMaps.keySet()){
                Opportunity updateOpp = new Opportunity(Id = oppId);
                Decimal amount = 0;
                Decimal volume = 0;
                Decimal margin = 0;
                for(Wholesale_Usage__c usage: oppUsageMaps.get(oppId)){
                    amount += usage.Revenue_Input__c == null ? 0 : usage.Revenue_Input__c;
                    volume += usage.Volume__c == null ? 0 : usage.Volume__c;
                    margin += usage.margin__c == null ? 0 : usage.margin__c;
                }
                margin = margin / oppUsageMaps.get(oppId).size() * 100;
                updateOpp.Amount = amount;
                updateOpp.Super_Network_Volume__c = volume;
                updateOpp.Super_Network_Wholesale_Profit__c = margin;
                updateOpps.add(updateOpp);
            }
            
            update updateOpps;
        }
  }