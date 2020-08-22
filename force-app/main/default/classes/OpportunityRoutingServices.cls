public without sharing class OpportunityRoutingServices {
    public class OppWrapper{
        public Id oppId;
        public String employeeSize;
        public Decimal monthlyRevenue;
        public String useCase;
        public String solutionCategory;
        public Boolean AESwitch;
        public Boolean IsShowcase;
        public Id AEOwner;
        public String Region;
        public String State;
        public String ZipCode;
        public String Country;
        public String City;
        public String product;
        public Decimal amount;
        public Boolean useCaseMatch;
        public Id ownerId;
        public String aeTier;
        public Boolean ignoreAE;
    }
    
    public class OppSettingWrapper{
        public Decimal amountCeiling;
        public Decimal amountFloor;
        public String employeeSize;
        public String solutionCategory;
        public String product;
        public String teamName;
        public String State;
        public String ZipCode;
        public String Country;
        public Id oppOwnerId;
        public Id specialistId;
        public String ownerName;
        public String specialistName;
        public String City;
        public String aeOwnerName;
        public Boolean aeOwnened;
        public Id AEOwnerId;
        public String aeTier;
        public String zipCodeFloor;
        public String zipCodeCeiling;
        public Boolean strategicAE;
        public Id recId;
        public Id groupId;
        public Id memberId;
    }
    
    public class AccountQBWrapper{
        public String city;
        public String country;
        public String employeeSize;
        public Id quarterBackId;
        public String teamName;
        public String State;
        public String ZipCode;
        public String quarterBackName;
        public String zipCodeFloor;
        public String zipCodeCeiling;
        public Id groupId;
        public Id memberId;
        
    }
    
    public static List<OppSettingWrapper> oppSettings {
        get{
            if(oppSettings == null){
                oppSettings = new List<OppSettingWrapper>();
                for(Opportunity_Routing_Rules__c rule: [
                        SELECT Zip_Code_Floor__c, Assignment_Group__c, Zip_Code_Ceiling__c, AM_Owned__c, AE_Owner__c, Strategic_AE__c, Revenue_Tier__c, Solution_Specialist__c, Solution_Specialist__r.Name, Amount_Ceiling__c, Amount_Floor__c, City__c, Country__c, Employee_Size__c, Solution_Category__c, Opportunity_Owner__c, Opportunity_Owner__r.Name, Sales_Team__c, State__c, Zip_Code__c, Product__c
                        FROM Opportunity_Routing_Rules__c
                    ]){
                    OppSettingWrapper wrapper = new OppSettingWrapper();
                    wrapper.amountFloor = rule.Amount_Floor__c;
                    wrapper.groupId = rule.Assignment_Group__c;
                    wrapper.amountCeiling = rule.Amount_Ceiling__c;
                    wrapper.strategicAE = rule.Strategic_AE__c;
                    wrapper.zipCodeFloor = rule.Zip_Code_Floor__c;
                    wrapper.zipCodeCeiling = rule.Zip_Code_Ceiling__c;
                    wrapper.ownerName = rule.Opportunity_Owner__r.Name;
                    wrapper.city = rule.City__c;
                    wrapper.country = rule.Country__c;
                    wrapper.product = rule.Product__c;
                    wrapper.solutionCategory = rule.Solution_Category__c;
                    wrapper.employeeSize = rule.Employee_Size__c;
                    wrapper.oppOwnerId = rule.Opportunity_Owner__c;
                    wrapper.teamName = rule.Sales_Team__c;
                    wrapper.state= rule.State__c;
                    wrapper.aeOwnened = rule.AM_Owned__c;
                    wrapper.AEOwnerId = rule.AE_Owner__c;
                    wrapper.aeTier = rule.Revenue_Tier__c;
                    wrapper.zipcode = rule.Zip_Code__c;
                    wrapper.specialistId = rule.Solution_Specialist__c;
                    wrapper.specialistName = rule.Solution_Specialist__r.Name;
                    wrapper.recId = rule.Id;
                    oppSettings.add(wrapper);
                }
            }
            return oppSettings;
        }
    }
    
    public static List<AccountQBWrapper> accountSettings {
        get{
            if(accountSettings == null){
                accountSettings = new List<AccountQBWrapper>();
                for(Account_Quarterback_Routing__c rule: [
                        SELECT Assignment_Group__c, Zip_Code_Floor__c, Zip_Code_Ceiling__c, City__c, Country__c, Employee_Size__c, Quarterback__c, Quarterback__r.Name, Sales_Team__c, State__c, Zip_Code__c
                        FROM Account_Quarterback_Routing__c
                    ]){
                    AccountQBWrapper wrapper = new AccountQBWrapper(); 
                    wrapper.groupId = rule.Assignment_Group__c;
                    wrapper.city = rule.City__c;
                    wrapper.country = rule.Country__c;
                    wrapper.employeeSize = rule.Employee_Size__c;
                    wrapper.quarterBackId = rule.Quarterback__c;
                    wrapper.quarterBackName = rule.Quarterback__r.Name;
                    wrapper.teamName = rule.Sales_Team__c;
                    wrapper.state= rule.State__c;
                    wrapper.zipcode = rule.Zip_Code__c;
                    wrapper.zipCodeFloor = rule.Zip_Code_Floor__c;
                    wrapper.zipCodeCeiling = rule.Zip_Code_Ceiling__c;
                    accountSettings.add(wrapper);
                }
            }
            return accountSettings;
        }
    }
    
    public static OppSettingWrapper findOppOwner(OppWrapper oppData){
        OppSettingWrapper omniChannelWildCard = null;
        OppSettingWrapper statePSWildCard = null;
        OppSettingWrapper countryPSWildCard = null;
        OppSettingWrapper stateWildCard = null;
        OppSettingWrapper countryWildCard = null;
        OppSettingWrapper aeWildCard = null;
        if(oppData.Country != 'United States' && oppData.zipCode != null){oppData.zipCode = oppData.zipCode.left(7);}
        else if(oppData.zipCode != null) oppData.zipCode = oppData.zipCode.left(5);
        for(OppSettingWrapper setting: oppSettings){
            Boolean productMatch = (setting.solutionCategory == '.*' && setting.product == oppData.product);
            Boolean solutionMatch = (setting.product == '.*' || setting.product == null && setting.solutionCategory == oppData.solutionCategory);
            String oppString = oppData.Country + oppData.State;
            String settingString = setting.Country + setting.State;
            Boolean zipCodeMatch = zipCodeinRange(oppData.zipCode, setting.zipCodeFloor, setting.zipCodeCeiling, setting.zipCode);
            if(setting.AEOwnerId == oppData.AEOwner && oppData.AEOwner != null && setting.strategicAE){
                if(solutionMatch || productMatch){
                    if(oppData.solutionCategory == 'Account Security' && solutionMatch && oppString == settingString && zipCodeMatch){
                        if(setting.amountFloor != null && oppData.amount >= setting.amountFloor && (setting.amountCeiling == null || setting.amountCeiling > oppData.amount)){
                            return setting;
                        }
                    }
                    else if(oppString == settingString && zipCodeMatch && oppData.solutionCategory != 'Account Security' && setting.solutionCategory != 'Account Security'){
                        return setting;
                    }
                }
                else if(setting.solutionCategory == '.*' && setting.product == null && oppString == settingString && zipCodeMatch){
                    return setting;
                }
                else if(setting.solutionCategory == '.*' && oppString == settingString){
                    omniChannelWildCard = setting;
                }
            }
            else if(setting.AEOwnerId == null && setting.AEOwnerId != oppData.AEOwner && !setting.strategicAE){
                //Priority 1: Perfect Match - Zip Code + State + ZipCode + EmployeeSize + Product/Solution Category
                if(oppString == settingString && zipCodeMatch && setting.employeeSize.contains(oppData.employeeSize) && (productMatch || solutionMatch)){
                    if(oppData.solutionCategory == 'Account Security' && solutionMatch){
                        if(setting.amountFloor != null && oppData.amount >= setting.amountFloor && (setting.amountCeiling == null || setting.amountCeiling > oppData.amount)){
                            return setting;
                        }
                    }
                    else{
                        return setting;
                    }
                }
                else if(setting.ZipCode == '.*' && setting.Country == oppData.Country && setting.State == oppData.State && setting.employeeSize.contains(oppData.employeeSize) && (productMatch || solutionMatch)){
                    if(oppData.solutionCategory == 'Account Security' && solutionMatch){
                        if(setting.amountFloor != null && oppData.amount >= setting.amountFloor && (setting.amountCeiling == null || setting.amountCeiling > oppData.amount)){
                            statePSWildCard = setting;
                        }
                    }
                    else{
                        statePSWildCard = setting;
                    }
                }
                else if((setting.State == null || setting.State == '.*') && setting.Country == oppData.Country && setting.employeeSize.contains(oppData.employeeSize) && (productMatch || solutionMatch)){
                    if(oppData.solutionCategory == 'Account Security' && solutionMatch){
                        if(setting.amountFloor != null && oppData.amount >= setting.amountFloor && (setting.amountCeiling == null || setting.amountCeiling > oppData.amount)){
                            countryPSWildCard = setting;
                        }
                    }
                    else{
                       countryPSWildCard = setting;
                    }
                }
                else if(setting.solutionCategory == '.*' && setting.employeeSize.contains(oppData.employeeSize) && oppString == settingString && zipCodeMatch){
                    omniChannelWildCard = setting;
                }
                else if((setting.ZipCode == null || setting.ZipCode == '.*') && setting.solutionCategory == '.*' && setting.Country == oppData.Country && setting.State == oppData.State && setting.employeeSize.contains(oppData.employeeSize)){
                    stateWildCard = setting;
                }
                else if((setting.State == null || setting.State == '.*') && setting.solutionCategory == '.*' && setting.Country == oppData.Country && setting.employeeSize.contains(oppData.employeeSize)){
                    countryWildCard = setting;
                }
            }
            /*if(setting.aeOwnened == oppData.AESwitch){
                Boolean productMatch = (setting.solutionCategory == '.*' && setting.product == oppData.product);
                Boolean solutionMatch = (setting.product == '.*' && setting.solutionCategory == oppData.solutionCategory);
                if(setting.aeOwnened){
                    if(setting.aeOwnerId == oppData.AEOwner && (solutionMatch || productMatch) && (oppData.aeTier != null && oppData.aeTier == setting.aeTier)){
                        return setting;
                    }
                    else if(setting.aeOwnerId == oppData.AEOwner){
                        aeWildCard = setting;
                    }
                }
                String oppString, settingString;
                oppString = oppData.Country + oppData.State;
                settingString = setting.Country + setting.State;
                Boolean zipCodeMatch = zipCodeinRange(oppData.zipCode, setting.zipCodeFloor, setting.zipCodeCeiling, setting.zipCode);
                //Priority 1: Perfect Match - Zip Code + State + ZipCode + EmployeeSize + Product/Solution Category
                if(oppString == settingString && zipCodeMatch && setting.employeeSize.contains(oppData.employeeSize) && (productMatch || solutionMatch)){
                    if(oppData.solutionCategory == 'Account Security' && solutionMatch){
                        if(setting.amountFloor != null && oppData.amount >= setting.amountFloor && (setting.amountCeiling == null || setting.amountCeiling > oppData.amount)){
                            return setting;
                        }
                    }
                    else{
                        return setting;
                    }
                }
                else if(!zipCodeMatch && setting.Country == oppData.Country && setting.State == oppData.State && setting.employeeSize.contains(oppData.employeeSize) && (productMatch || solutionMatch)){
                    if(oppData.solutionCategory == 'Account Security' && solutionMatch){
                        if(setting.amountFloor != null && oppData.amount >= setting.amountFloor && (setting.amountCeiling == null || setting.amountCeiling > oppData.amount)){
                            statePSWildCard = setting;
                        }
                    }
                    else{
                        statePSWildCard = setting;
                    }
                }
                else if((setting.State == null || setting.State == '.*') && setting.Country == oppData.Country && setting.employeeSize.contains(oppData.employeeSize) && (productMatch || solutionMatch)){
                    if(oppData.solutionCategory == 'Account Security' && solutionMatch){
                        if(setting.amountFloor != null && oppData.amount >= setting.amountFloor && (setting.amountCeiling == null || setting.amountCeiling > oppData.amount)){
                            countryPSWildCard = setting;
                        }
                    }
                    else{
                       countryPSWildCard = setting;
                    }
                }
                else if(setting.solutionCategory == '.*' && setting.product == '.*' && setting.employeeSize.contains(oppData.employeeSize) && oppString == settingString && zipCodeMatch){
                    omniChannelWildCard = setting;
                }
                else if((setting.ZipCode == null || setting.ZipCode == '.*') && setting.solutionCategory == '.*' && setting.product == '.*' && setting.Country == oppData.Country && setting.State == oppData.State && setting.employeeSize.contains(oppData.employeeSize)){
                    stateWildCard = setting;
                }
                else if((setting.State == null || setting.State == '.*') && setting.solutionCategory == '.*' && setting.product == '.*' && setting.Country == oppData.Country && setting.employeeSize.contains(oppData.employeeSize)){
                    countryWildCard = setting;
                }
            }*/
        }
        system.debug(JSON.serialize(oppData));
        system.debug(JSON.serialize(statePSWildCard));
        system.debug(JSON.serialize(countryPSWildCard));
        system.debug(JSON.serialize(omniChannelWildCard));
        if(oppData.AESwitch && aeWildCard != null) return aeWildCard;
        if(statePSWildCard != null) return statePSWildCard;
        if(countryPSWildCard != null) return countryPSWildCard;
        if(omniChannelWildCard != null) return omniChannelWildCard;
        if(stateWildCard != null) return stateWildCard;
        if(countryWildCard != null) return countryWildCard;
        return null;
    }
    
    public static OppSettingWrapper findSpecialist(OppWrapper oppData){
        OppSettingWrapper omniChannelWildCard = null;
        OppSettingWrapper statePSWildCard = null;
        OppSettingWrapper countryPSWildCard = null;
        OppSettingWrapper stateWildCard = null;
        OppSettingWrapper countryWildCard = null;
        OppSettingWrapper aeWildCard = null;
        if(oppData.Country != 'United States' && oppData.zipCode != null){oppData.zipCode = oppData.zipCode.left(7);}
        if(oppData.zipCode != null) oppData.zipCode = oppData.zipCode.left(5);
        
        for(OppSettingWrapper setting: oppSettings){
            Boolean productMatch = (setting.solutionCategory == '.*');
            Boolean solutionMatch = (setting.product == '.*' || setting.product == null && setting.solutionCategory == oppData.solutionCategory);
            if((setting.AEOwnerId == oppData.AEOwner && setting.strategicAE || oppData.ignoreAE) && oppData.solutionCategory == 'Account Security' && solutionMatch){
                String oppString = oppData.Country + oppData.State;
                String settingString = setting.Country + setting.State;
                Boolean zipCodeMatch = zipCodeinRange(oppData.zipCode, setting.zipCodeFloor, setting.zipCodeCeiling, setting.zipCode);
                if(oppString == settingString && zipCodeMatch && setting.employeeSize.contains(oppData.employeeSize)){
                    return setting;
                }
                else if(!zipCodeMatch && oppString == settingString && setting.employeeSize.contains(oppData.employeeSize)){
                     statePSWildCard = setting;
                }
                else if(!zipCodeMatch && setting.Country == oppData.Country && setting.employeeSize.contains(oppData.employeeSize)){
                    countryPSWildCard = setting;
                }
            }
        }
        if(oppData.AESwitch && aeWildCard != null) return aeWildCard;
        if(statePSWildCard != null) return statePSWildCard;
        if(countryPSWildCard != null) return countryPSWildCard;
        if(omniChannelWildCard != null) return omniChannelWildCard;
        if(stateWildCard != null) return stateWildCard;
        if(countryWildCard != null) return countryWildCard;
        return null;
    }
    
    public static AccountQBWrapper findAccountQB(OppWrapper oppData){
        /*AccountQBWrapper stateWildCard = null;
        AccountQBWrapper countryWildCard = null;
        if(oppData.Country != 'United States' && oppData.zipCode != null){oppData.zipCode = oppData.zipCode.left(7);}
        if(oppData.zipCode != null) oppData.zipCode = oppData.zipCode.left(5);
        for(AccountQBWrapper setting: accountSettings){
            String oppString, settingString;
            oppString = oppData.Country + oppData.State;
            settingString = setting.Country + setting.State;
            Boolean zipCodeMatch = zipCodeinRange(oppData.zipCode, setting.zipCodeFloor, setting.zipCodeCeiling, setting.zipCode);
            if(oppString == settingString && zipCodeMatch && setting.employeeSize.contains(oppData.employeeSize)){
                return setting;
            }
            else if((setting.ZipCode == '.*' || setting.Zipcode == null && setting.zipCodeFloor == null && setting.zipCodeCeiling == null) && setting.Country == oppData.Country && setting.State == oppData.State && setting.employeeSize.contains(oppData.employeeSize)){
                stateWildCard = setting;
            }
            else if((setting.State == null || setting.State == '.*') && setting.Country == oppData.Country && setting.employeeSize.contains(oppData.employeeSize)){
                countryWildCard = setting;
            }
        }
        system.debug(Json.serialize(oppData) + json.serialize(countryWildCard));
        if(stateWildCard != null) return stateWildCard;
        if(countryWildCard != null) return countryWildCard;*/
        return null;
    }
    
    public static void getRoundRobinOwnerId(OppSettingWrapper wrapper){
        if(wrapper.groupId == null) return;
        Assignment_Group_Name__c userGroup = [SELECT Id, ( SELECT Id, Last_Assignment__c, Millisecond__c, User__c, User__r.Name 
                                                                        FROM Assignment_Groups__r
                                                                        WHERE Active__c = 'True' AND User_Active__c = 'True')
                                                           FROM Assignment_Group_Name__c
                                                           WHERE Id =: wrapper.groupId];
        if(userGroup.Assignment_Groups__r == null || userGroup.Assignment_Groups__r.isEmpty()) return;                                        
        List<Assignment_Groups__c> sortedMembers = MQLRoundRobinServices.sortMemebersByLastAssignmentTime(userGroup.Assignment_Groups__r);
        wrapper.memberId = sortedMembers[0].Id;
        wrapper.oppOwnerId = sortedMembers[0].User__c;
        wrapper.ownerName = sortedMembers[0].User__r.Name;
    }
    
    public static void getRoundRobinAEOwner(AccountQBWrapper wrapper){
        if(wrapper.groupId == null) return;
        Assignment_Group_Name__c userGroup = [SELECT Id, ( SELECT Id, Last_Assignment__c, Millisecond__c, User__c, User__r.Name 
                                                                        FROM Assignment_Groups__r
                                                                        WHERE Active__c = 'True' AND User_Active__c = 'True')
                                                           FROM Assignment_Group_Name__c
                                                           WHERE Id =: wrapper.groupId];
        if(userGroup.Assignment_Groups__r == null || userGroup.Assignment_Groups__r.isEmpty()) return;                                        
        List<Assignment_Groups__c> sortedMembers = MQLRoundRobinServices.sortMemebersByLastAssignmentTime(userGroup.Assignment_Groups__r);
        wrapper.memberId = sortedMembers[0].Id;
        wrapper.quarterBackId = sortedMembers[0].User__c;
        wrapper.quarterBackName = sortedMembers[0].User__r.Name;
    }
    
    @TestVisible
    public static Boolean zipCodeinRange(String objZipCode, String lowerBound, String upperBound, String settingZipCode){
        if(objZipCode == null) return false;
        if(settingZipCode != null && objZipCode == settingZipCode) return true;
        else if(settingZipCode != null) return false;
        if(lowerBound == null) return false;
        system.debug(objZipCode >= lowerBound && (upperBound == null || objZipCode <= upperBound));
        if(objZipCode >= lowerBound && (upperBound == null || objZipCode <= upperBound)) return true;
        else return false;
    }
    
    /*public static List<SettingWrapper> settings {
        get{
            if(settings == null){
                settings = new List<SettingWrapper>();
                for(Opportunity_Routing_Rules__c rule: Opportunity_Routing_Rules__c.getAll().values()){
                    SettingWrapper wrapper = new SettingWrapper();
                    //wrapper.showCaseEmployeeSize = rule.Showcase_Employee_Size__c != null ? rule.Showcase_Employee_Size__c.remove('\\') : null;
                    //wrapper.detailEmployeeSize = rule.Employee_Size_Details__c;
                    wrapper.employeeSize = rule.Employee_Size__c;
                    wrapper.State = rule.State_Full__c;
                    wrapper.Country = rule.Country_Name__c;
                    wrapper.ZipCode = rule.Zip_Code__c;
                    wrapper.City = rule.City__c;
                    wrapper.ownerId = rule.Owner_Id__c;
                    wrapper.AEOwnerId = rule.Owner_Id__c;
                    wrapper.solution = rule.Solution_Category__c;
                    wrapper.specialistId = rule.Specialist_Id__c;
                    wrapper.AEOwned = rule.AE_Owned__c;
                    wrapper.product = rule.Product__c;
                    settings.add(wrapper);
                }
            }
            return settings;
        } 
        set;
        
    }
    
    public static Map<Id, SettingWrapper> getOppOwners(List<OppWrapper> opps){
        Map<Id, SettingWrapper> resultMap = new Map<Id, SettingWrapper>();
        if(opps != null && !opps.isEmpty()){
           for(OppWrapper opp: opps){
              SettingWrapper wrapper = findOppOwner(opp);
              if(wrapper != null){
                  resultMap.put(opp.oppId, wrapper);
              }
           }
        }
        return resultMap;
    }
    
    @TestVisible
    private static SettingWrapper findOppOwner(OppWrapper oppData){
        SettingWrapper useCaseWildCard = null;
        SettingWrapper stateWildCard = null;
        SettingWrapper countryWildCard = null;
        SettingWrapper productWildCard = null;
        SettingWrapper solutionWildCard = null;
        for(SettingWrapper setting: settings){
            if(!setting.AEOwned){
                String oppString, settingString, employeeSizeString;
                oppString = oppData.Country + oppData.State;
                settingString = setting.Country + setting.State;
                //if(oppData.State == 'California'){
                //    oppString += oppData.City;
                //    settingString += setting.City;
                //}
                oppString += oppData.employeeSize;
                settingString += oppData.IsShowcase ? setting.showCaseEmployeeSize : setting.employeeSize + setting.detailEmployeeSize;
                if(oppString == settingString){
                    if(oppData.product == setting.product){
                        if(setting.solution == null || setting.solution == '.*'){
                            productWildCard = setting;
                        }
                        else if(setting.solution == oppData.solution){
                            return setting;
                        }
                    }
                    else if(oppData.solution == setting.solution){
                        if(setting.product == null || setting.product == '.*'){
                            solutionWildCard = setting;
                        }
                    }
                    else if((setting.solution == null || setting.solution == '.*') && (setting.product == null || setting.product == '.*')){
                        useCaseWildCard = setting;
                    }
                }
                else if(setting.ZipCode == '.*' && setting.Country == oppData.Country && setting.State == oppData.State ){
                    stateWildCard = setting;
                }
                else if(setting.State == '.*' && setting.Country == oppData.Country){
                    countryWildCard = setting;
                }
            }
        }
        if(stateWildCard != null) return stateWildCard;
        if(countryWildCard != null) return countryWildCard;
        if(productWildCard != null) return productWildCard;
        if(solutionWildCard != null) return solutionWildCard;
        if(useCaseWildCard != null) return useCaseWildCard;
        return null;
    }
    
    public static SettingWrapper findAESpecialist(OppWrapper oppData){
        SettingWrapper useCaseWildCard = null;
        SettingWrapper productWildCard = null;
        SettingWrapper solutionWildCard = null;
        for(SettingWrapper setting: settings){
            if(setting.AEOwned && oppData.ownerId == setting.OwnerId){
                if(oppData.product == setting.product){
                    if(setting.solution == null || setting.solution == '.*'){
                        productWildCard = setting;
                    }
                    else if(setting.solution == oppData.solution){
                        return setting;
                    }
                }
                else if(oppData.solution == setting.solution){
                    if(setting.product == null || setting.product == '.*'){
                        solutionWildCard = setting;
                    }
                }
                else if((setting.solution == null || setting.solution == '.*') && (setting.product == null || setting.product == '.*')){
                    useCaseWildCard = setting;
                }
            }
        }
        if(productWildCard != null) return productWildCard;
        if(solutionWildCard != null) return solutionWildCard;
        if(useCaseWildCard != null) return useCaseWildCard;
        return null;
    }*/
}