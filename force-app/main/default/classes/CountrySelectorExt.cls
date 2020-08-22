public with sharing class CountrySelectorExt {
    public class CountryException extends Exception {}
    
    public class Types{
        public String typeId;
        public String countryId;
        public Boolean checked;
    }
    
    public static Map<String, Decimal> numberOrderMap {
        get{
            if(numberOrderMap == null){
                numberOrderMap = new Map<String, Decimal>();
                List<Country_Phone_Number_Type_Order__c> settings = Country_Phone_Number_Type_Order__c.getAll().values();
                
                for(Country_Phone_Number_Type_Order__c setting: settings){
                    Decimal orderNumber = setting.Column__c == 'Left' ? setting.Order__c * 2 : setting.Order__c * 2 + 1;
                    numberOrderMap.put(setting.Phone_Number_Type_Name__c, orderNumber);
                }
            }
            return numberOrderMap;
        }
        set;
    }
    
    public Id recordId {get; set;}
    
    public CountrySelectorExt(ApexPages.standardController stdCtrl){
        recordId = stdCtrl.getId();
    }
    
    public String getCountries(){
        List<Country__c> countries = [SELECT Name, CountryName__c, Region__c FROM Country__c ORDER BY Name];
        return JSON.serialize(countries);
    }
    
    public String getCountryTypeMap(){
        List<Country_Phone_Number_Type__c> types = [SELECT Name, Phone_Number_Type__r.Name, Status__c, Country__c, Country__r.Name, Origin__c FROM Country_Phone_Number_Type__c WHERE Country__c != null AND Show_in_VF_Page__c != false];
        Map<Id, List<Country_Phone_Number_Type__c>> resultMap = new Map<Id, List<Country_Phone_Number_Type__c>>();
        for(Country_Phone_Number_Type__c aType: types){
            List<Country_Phone_Number_Type__c> typeList = resultMap.get(aType.Country__c);
            if(typeList != null && !typeList.isEmpty()){
                Boolean alreadyAdded = false;
                Decimal newElementNumber = numberOrderMap.get(aType.Phone_Number_Type__r.Name);
                if(newElementNumber != null){
                    for(Integer i = 0; i < typeList.size(); i++){
                        Decimal listElementOrder = numberOrderMap.get(typeList[i].Phone_Number_Type__r.Name);
                        if(listElementOrder != null && listElementOrder > newElementNumber){
                            typeList.add(i, aType);
                            alreadyAdded = true;
                            break;
                        }
                    }
                }
                if(!alreadyAdded) typeList.add(aType);
            }
            else{
                resultMap.put(aType.Country__c, new List<Country_Phone_Number_Type__c>{aType});
            }
        }
        return JSON.serialize(resultMap);
    }
    
    public String getExistingRecords(){
        List<Opportunity_Country__c> existingCountries = [SELECT Country__r.Name, (SELECT Country_Number_Type__c FROM Opportunity_Country_Numbers__r) FROM Opportunity_Country__c WHERE Opportunity__c= :recordId ORDER BY Country__r.Name];
        return JSON.serialize(existingCountries);
    }
    
    @RemoteAction
    public static void saveData(String oppCountry, String types, String oppId){
        List<Opportunity_Country__c> saveCountries = (List<Opportunity_Country__c>) JSON.deserialize(oppCountry, List<Opportunity_Country__c>.class);
        Map<Id, Opportunity_Country__c> insertCountries = new Map<Id, Opportunity_Country__c>();
        Map<Id, Opportunity_Country__c> countryIdMap = new Map<Id, Opportunity_Country__c>();
        List<Types> saveTypes = (List<Types>) JSON.deserialize(types, List<Types>.class);
        
        List<Opportunity_Country__c> existingCountries = [SELECT Country__c FROM Opportunity_Country__c WHERE Opportunity__c= :oppId];
        Set<Id> countryIds = new Set<Id>();
        
        for(Opportunity_Country__c country: existingCountries){
            countryIds.add(country.Country__c);
            countryIdMap.put(country.Country__c, country);
        }
        
        for(Opportunity_Country__c saveCountry: saveCountries){
            if(!countryIds.contains(saveCountry.Country__c)){
                insertCountries.put(saveCountry.Country__c, saveCountry);
            }
        }

        SavePoint sp = Database.setSavepoint();
        insert insertCountries.values();
        countryIdMap.putAll(insertCountries);

        List<Opportunity_Country_Number__c> insertTypes = new List<Opportunity_Country_Number__c>();
        List<Opportunity_Country_Number__c> deleteTypes = new List<Opportunity_Country_Number__c>();
        
        List<Opportunity_Country_Number__c> existingTypes = [SELECT Country_Number_Type__c, Opportunity_Country__r.Country__c FROM Opportunity_Country_Number__c WHERE Opportunity_Country__r.Opportunity__c = :oppId AND Opportunity_Country__r.Opportunity__c != null AND Country_Number_Type__c != null];
        
        for(Types aType: saveTypes){
            String status = '';
            
            for(Opportunity_Country_Number__c existingType: existingTypes){
                system.debug('---' + aType + '---' + existingType);
                if((aType.typeId != existingType.Country_Number_Type__c || aType.countryId != existingType.Opportunity_Country__r.Country__c) && aType.checked){
                    status = 'Insert';
                }
                else if(aType.typeId == existingType.Country_Number_Type__c && aType.countryId == existingType.Opportunity_Country__r.Country__c){
                    if(aType.checked){
                        status = '';
                    }
                    else{
                        deleteTypes.add(existingType);
                        status = 'Delete';
                    }
                    break;
                }
            }
            if(status == 'Insert' || (existingTypes.isEmpty() && aType.checked)){
                insertTypes.add(new Opportunity_Country_Number__c(Country_Number_Type__c = aType.typeId, Opportunity_Country__c = countryIdMap.get(aType.countryId).Id));
            }
        }
        
        try{
            delete deleteTypes;
            insert insertTypes;
        }
        catch(DMLException e){
            Database.rollback(sp);
            throw new CountryException(e.getStackTraceString());
        }
    }
}