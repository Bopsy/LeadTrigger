public with sharing class MQLRoundRobinServices {

    @TestVisible
    private static Boolean bypassTrigger = false;
    @TestVisible
    private static final String ALL_NULL = 'ALL NULL';
    @TestVisible
    private static final String WILD_CARD = '*';
    @TestVisible
    private static final String UNKNOWN = '[Unknown]';

    static Map<String, String> timeZoneSettings {
        get{
           if(timeZoneSettings == null){
               timeZoneSettings = new Map<String, String>();
               for(MQL_TimeZone__c setting: MQL_TimeZone__c.getAll().values()){
                   String keyString = setting.Country__c;
                   if(setting.State__c != null) keyString += '-' + setting.State__c;
                   timeZoneSettings.put(keyString, setting.TimeZone__c);
               }
           }
           return timeZoneSettings;
        }
        set;
    }
    
    public static Map<String, Id> groupMappings {
        get{
            if(groupMappings == null){
                groupMappings = new Map<String, Id>();
                
                for(Group_Mapping__c mapping: [SELECT Campaign_SubType__c, Campaign_Id__c, Account_Owner__c, State__c, Priority__c, Channel__c, Country__c, TimeZone__c,
                                               Group_Name__c, Group_Name__r.RecordTypeId, Product__c FROM Group_Mapping__c ORDER BY Priority__c]){
                    
                                                  
					String keyString = ALL_NULL;
                    if(mapping.Campaign_Id__c != null){
                        keyString = mapping.Campaign_Id__c;
                    }
                    else if(mapping.Account_Owner__c != WILD_CARD && mapping.Account_Owner__c != null){
                        keyString = mapping.Account_Owner__c;
                    }
                    else if(mapping.Country__c != WILD_CARD && mapping.Country__c != null){
                        if(mapping.Country__c == UNKNOWN || mapping.Country__c == 'United States' || mapping.Country__c == 'Canada'){
                            if(mapping.State__c != null && mapping.State__c != WILD_CARD){
                                keyString = mapping.Country__c + '-' +  mapping.State__c;
                                if(mapping.Channel__c != null) keyString += '-' + mapping.Channel__c;
                                if(mapping.Campaign_SubType__c != null) keyString += '-' + mapping.Campaign_SubType__c;
                            }
                            else {
                                keyString = mapping.Country__c + '-' + mapping.Channel__c;
                                if(mapping.Campaign_SubType__c != null) keyString += '-' + mapping.Campaign_SubType__c;
                            }
                        }
                        else{
                            if(mapping.State__c != null && mapping.State__c != WILD_CARD){
                                keyString = mapping.Country__c + mapping.State__c;
                            }
                            else if(mapping.Channel__c != null && mapping.Channel__c != WILD_CARD){
                                keyString = mapping.Country__c + '-' + mapping.Channel__c;
                                if(mapping.Campaign_SubType__c != null) keyString += '-' + mapping.Campaign_SubType__c;
                            }
                            else{
                                keyString = mapping.Country__c;
                            }
                        }
                    }
                    else if(mapping.Product__c != WILD_CARD && mapping.Product__c != null){
                        keyString = mapping.Product__c;
                    }
                    else if(mapping.TimeZone__c != WILD_CARD && mapping.TimeZone__c != null){
                        keyString = mapping.TimeZone__c + '-' + mapping.Channel__c;
                    }
                    else if(mapping.Channel__c != WILD_CARD && mapping.Channel__c != null){
                        keyString = mapping.Channel__c;
                    }
                    groupMappings.put(keyString, mapping.Group_Name__c);
                }
            }
            System.debug('groupMappings mql-->'+groupMappings);
            return groupMappings;
        }
        set;
    }
    
    public static Map<String, Decimal> groupPriority{
        get{
            if(groupPriority == null){
                groupPriority = new Map<String, Decimal>();
                for(Group_Mapping__c mapping: [SELECT Campaign_SubType__c, Campaign_Id__c, Account_Owner__c, State__c, Priority__c, Channel__c, Country__c, TimeZone__c, Group_Name__c, Product__c FROM Group_Mapping__c ORDER BY Priority__c]){
                    String keyString = ALL_NULL;
                    if(mapping.Campaign_Id__c != null){
                        keyString = mapping.Campaign_Id__c;
                    }
                    else if(mapping.Account_Owner__c != WILD_CARD && mapping.Account_Owner__c != null){
                        keyString = mapping.Account_Owner__c;
                    }
                    else if(mapping.Country__c != WILD_CARD && mapping.Country__c != null){
                        if(mapping.Country__c == UNKNOWN || mapping.Country__c == 'United States' || mapping.Country__c == 'Canada'){
                            if(mapping.State__c != null && mapping.State__c != WILD_CARD){
                                keyString = mapping.Country__c + '-' +  mapping.State__c;
                                if(mapping.Channel__c != null) keyString += '-' + mapping.Channel__c;
                                if(mapping.Campaign_SubType__c != null) keyString += '-' + mapping.Campaign_SubType__c;
                            }
                            else {
                                keyString = mapping.Country__c + '-' + mapping.Channel__c;
                                if(mapping.Campaign_SubType__c != null) keyString += '-' + mapping.Campaign_SubType__c;
                            }
                        }
                        else{
                            if(mapping.State__c != null && mapping.State__c != WILD_CARD){
                                keyString = mapping.Country__c + mapping.State__c;
                            }
                            else if(mapping.Channel__c != null && mapping.Channel__c != WILD_CARD){
                                keyString = mapping.Country__c + '-' + mapping.Channel__c;
                                if(mapping.Campaign_SubType__c != null) keyString += '-' + mapping.Campaign_SubType__c;
                            }
                            else{
                                keyString = mapping.Country__c;
                            }
                        }
                    }
                    else if(mapping.Product__c != WILD_CARD && mapping.Product__c != null){
                        keyString = mapping.Product__c;
                    }
                    else if(mapping.TimeZone__c != WILD_CARD && mapping.TimeZone__c != null){
                        keyString = mapping.TimeZone__c + '-' + mapping.Channel__c;
                    }
                    else if(mapping.Channel__c != WILD_CARD && mapping.Channel__c != null){
                        keyString = mapping.Channel__c;
                        if(mapping.Campaign_SubType__c != null) keyString += '-' + mapping.Campaign_SubType__c;
                    }
                    groupPriority.put(keyString, mapping.Priority__c);
                }
            }
            return groupPriority;
        }
        set;
    }


    public static void beforeInsert(List<FSR__c> newRecords){
        if(bypassTrigger) return;
        setTimeZone(newRecords);
        List<FSR__c> filteredRecords = toRoundRobin(newRecords, new Map<Id, FSR__c>());
        processMQL(filteredRecords);
        //bypassTrigger = true;
    }

    public static void beforeUpdate(List<FSR__c> newRecords, Map<Id, FSR__c> oldMap){
        if(bypassTrigger) return;
        setTimeZone(newRecords);
        List<FSR__c> filteredRecords = toRoundRobin(newRecords, oldMap);
        processMQL(filteredRecords);
        //bypassTrigger = true;
    }

    private static List<FSR__c> toRoundRobin(List<FSR__c> newRecords, Map<Id, FSR__c> oldMap) {
        
        List<FSR__c> results = new List<FSR__c>();
        for (FSR__c newRecord: newRecords){
            
            FSR__c oldRecord = oldMap.get(newRecord.Id);
            if (oldRecord != null){
                if (newRecord.Requires_MQL_Assignment__c == true &&
                    newRecord.Requires_MQL_Assignment__c != oldRecord.Requires_MQL_Assignment__c
                   ) {
                       results.add(newRecord);
                   }
            }
            else if (newRecord.Requires_MQL_Assignment__c == true) {
                results.add(newRecord);
            }
        }
        return results;
    }

    @TestVisible
    private static void processMQL(List<FSR__c> records){

        Map<Id, List<Assignment_Groups__c>> groupIdToMembersMap = new Map<Id, List<Assignment_Groups__c>>();
		for(Assignment_Group_Name__c assignmentGroup : [SELECT Id,RecordTypeId, ( SELECT Id, Last_Assignment__c, Millisecond__c, User__c
                                                                    FROM Assignment_Groups__r
                                                                    WHERE Active__c = 'True' AND User_Active__c = 'True')
                                                       FROM Assignment_Group_Name__c
                                                       WHERE Id =: groupMappings.values() ]){
			System.debug('assignmentGroup-->'+assignmentGroup);
            List<Assignment_Groups__c> sortedMembers = sortMemebersByLastAssignmentTime(assignmentGroup.Assignment_Groups__r);
            groupIdToMembersMap.put(assignmentGroup.Id, sortedMembers);
        }
        Map<Id, Assignment_Groups__c> updateMembersMap = new Map<Id, Assignment_Groups__c>();

        for(FSR__c mql : records){
            if(mql.Assign_MQL_Owner__c != null){
                mql.OwnerId = mql.Assign_MQL_Owner__c;
                mql.Requires_MQL_Assignment__c = false;
                //Added Disposition Time for Live Chat MQL
                if(mql.SLA_Start_Time__c == null) mql.SLA_Start_Time__c = Datetime.now();
                if(mql.Dispositioned_Date__c == null) mql.Dispositioned_Date__c = Datetime.now();
            }
            else{
                Id groupId = findMqlGroupId(mql, groupMappings, groupPriority);
                System.debug(groupId);
                if(groupId != null){
                    List<Assignment_Groups__c> members = new List<Assignment_Groups__c>();
                    if(groupIdToMembersMap.containsKey(groupId))
                        members = groupIdToMembersMap.get(groupId);
                    System.debug('members-MQL->'+members);
                    if(!members.isEmpty()){
                        Assignment_Groups__c element = members[0];
                        mql.OwnerId = members[0].User__c;
                        mql.Requires_MQL_Assignment__c = false;
                        Datetime now = Datetime.now();
                        members[0].Last_Assignment__c = now;
                        members[0].Millisecond__c = now.millisecondGMT();
                        members = sortMemebersByLastAssignmentTime(members);
                        updateMembersMap.put(element.Id, element.clone(true, true, true, true));
                        //members.add(element);
                        groupIdToMembersMap.put(groupId, members);
                    }
                }
            }
        }
		System.debug(records);
        update updateMembersMap.values();

    }

    @TestVisible
    private static void setTimeZone(List<FSR__c> mqls){
        for(FSR__c mql: mqls){
            String keyString = mql.Country__c;
            if(mql.State__c != null && mql.Country__c == 'United States' || mql.Country__c == 'Canada') keyString += '-' + mql.State__c;
            String timeZoneOffset = timeZoneSettings.get(keyString);
            mql.TimeZone__c = (timeZoneOffset != null) ? timeZoneOffset : mql.TimeZone__c;
        }
    }

    @TestVisible
    private static Id findMqlGroupId(FSR__c mql, Map<String, Id> groupMappings, Map<String, Decimal> groupPriority){
        Id result = null;
        String timeZoneString = mql.TimeZone__c + '-' + mql.Campaign_Type__c;
        String unknownCountryStateString = mql.Country__c + '-' + mql.State__c + '-' + mql.Campaign_Type__c;
        String unknownCountryStateSubString = mql.Country__c + '-' + mql.State__c + '-' + mql.Campaign_Type__c  + '-' + mql.Campaign_Sub_Type__c;
        String unknownCountryString = mql.Country__c + '-' + mql.Campaign_Type__c;
        String unknownCountrySubString = mql.Country__c + '-' + mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c;
        Decimal priority = groupPriority.get(mql.Account_Owner__c);
        result = groupMappings.get(mql.Account_Owner__c);
        if(mql.Campaign_Id__c != null){
            priority = groupPriority.get(mql.Campaign_Id__c);
            result = groupMappings.get(mql.Campaign_Id__c);
        }
        if(mql.Country__c != UNKNOWN && mql.Country__c != null){
            if(priority == null || (groupPriority.get(mql.Country__c + '-' + mql.State__c + '-' + mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c) != null && priority > groupPriority.get(mql.Country__c + '-' + mql.State__c+ '-' + mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c))){
                priority = groupPriority.get(mql.Country__c + '-' + mql.State__c + '-' + mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c);
                result = groupMappings.get(mql.Country__c + '-' + mql.State__c + '-' + mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c);
            }
            if(priority == null || (groupPriority.get(mql.Country__c + '-' + mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c) != null && priority > groupPriority.get(mql.Country__c + '-' + mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c))){
                priority = groupPriority.get(mql.Country__c + '-' + mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c);
                result = groupMappings.get(mql.Country__c + '-' + mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c);
            }
            if(priority == null || (groupPriority.get(mql.Country__c + '-' + mql.State__c + '-' + mql.Campaign_Type__c) != null && priority > groupPriority.get(mql.Country__c + '-' + mql.State__c+ '-' + mql.Campaign_Type__c))){
                priority = groupPriority.get(mql.Country__c + '-' + mql.State__c + '-' + mql.Campaign_Type__c);
                result = groupMappings.get(mql.Country__c + '-' + mql.State__c + '-' + mql.Campaign_Type__c);
            }
            
            if(priority == null || (groupPriority.get(mql.Country__c + '-' + mql.State__c) != null && priority > groupPriority.get(mql.Country__c + '-' + mql.State__c))){
                priority = groupPriority.get(mql.Country__c + '-' + mql.State__c);
                result = groupMappings.get(mql.Country__c + '-' + mql.State__c);
            }
            if(priority == null || (groupPriority.get(mql.Country__c) != null && priority > groupPriority.get(mql.Country__c))){
                priority = groupPriority.get(mql.Country__c);
                result = groupMappings.get(mql.Country__c);
            }
        }
        if(priority == null || (groupPriority.get(mql.Grossreg_Product__c) != null && priority > groupPriority.get(mql.Grossreg_Product__c))){
            priority = groupPriority.get(mql.Grossreg_Product__c);
            result = groupMappings.get(mql.Grossreg_Product__c);
        }
        if(priority == null || (groupPriority.get(timeZoneString) != null && priority > groupPriority.get(timeZoneString))){
            priority = groupPriority.get(timeZoneString);
            result = groupMappings.get(timeZoneString);
        }
        if(priority == null || (groupPriority.get(mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c) != null && priority > groupPriority.get(mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c))){
            priority = groupPriority.get(mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c);
            result = groupMappings.get(mql.Campaign_Type__c + '-' + mql.Campaign_Sub_Type__c);
        }
        if(priority == null || (groupPriority.get(mql.Campaign_Type__c) != null && priority > groupPriority.get(mql.Campaign_Type__c))){
            priority = groupPriority.get(mql.Campaign_Type__c);
            result = groupMappings.get(mql.Campaign_Type__c);
        }
        if((mql.Country__c == UNKNOWN || mql.Country__c == 'United States' || mql.Country__c == 'Canada')){
            if(priority == null || (groupPriority.get(unknownCountryStateString) != null && priority > groupPriority.get(unknownCountryStateString))){
                priority = groupPriority.get(unknownCountryStateString);
                result = groupMappings.get(unknownCountryStateString);
            }
            if(priority == null || (groupPriority.get(unknownCountryStateSubString) != null && priority > groupPriority.get(unknownCountryStateSubString))){
                priority = groupPriority.get(unknownCountryStateString);
            }
        }
        if(priority == null || (groupPriority.get(unknownCountrySubString) != null && priority > groupPriority.get(unknownCountrySubString))){
            priority = groupPriority.get(unknownCountrySubString);
            result = groupMappings.get(unknownCountrySubString);
        }
        if(priority == null || (groupPriority.get(unknownCountryString) != null && priority > groupPriority.get(unknownCountryString))){
            priority = groupPriority.get(unknownCountryString);
            result = groupMappings.get(unknownCountryString);
        }
        if(result == null){
            result = groupMappings.get(ALL_NULL);
        }
        System.debug(result);
        return result;
    }

    public static List<Assignment_Groups__c> sortMemebersByLastAssignmentTime(List<Assignment_Groups__c> members){
        List<Assignment_Groups__c> result = new List<Assignment_Groups__c>();
        if(members == null || members.isEmpty()) return result;
        
        for(integer i = 0; i < members.size(); i++){
            for(integer j = 0; j <  members.size() - 1 - i; j++){
                if(members[j].Last_Assignment__c == null) members[j].Last_Assignment__c = Datetime.newInstance(1970,1,1,0,0,0);
                if(members[j+1].Last_Assignment__c == null) members[j+1].Last_Assignment__c = Datetime.newInstance(1970,1,1,0,0,0);
                if(members[j].Last_Assignment__c.getTime() > members[j + 1].Last_Assignment__c.getTime()){
                    Assignment_Groups__c temp = members[j];
                    members[j] = members[j+1];
                    members[j+1] = temp;
                }
            }
        }
        result = members;
        return result;
    }

}