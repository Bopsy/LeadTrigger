public class PartnerInquiryRoundRobin {
    
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
        System.debug('newRecords-->'+newRecords);
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
                System.debug('mql assignment');
                results.add(newRecord);
            }
        }
        return results;
    }
    
    @TestVisible
    private static void processMQL(List<FSR__c> records){
        try{
            Map<Id, List<Assignment_Groups__c>> groupIdToMembersMap = new Map<Id, List<Assignment_Groups__c>>();
            
            //fetch only Partner type Assignment type Group
            Id inqPartnerRecordTypeId = Schema.SObjectType.Assignment_Group_Name__c.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
            /*System.debug('assignmentGroupPartner-1->'+[SELECT Id, ( SELECT Id, Last_Assignment__c, Millisecond__c, User__c
                                                                   FROM Assignment_Groups__r
                                                                   WHERE Active__c = 'True' AND User_Active__c = 'True')
                                                       FROM Assignment_Group_Name__c
                                                       WHERE RecordTypeId =:inqPartnerRecordTypeId ]);
            System.debug('assignmentGroupPartner-2->'+[SELECT Id, ( SELECT Id, Last_Assignment__c, Millisecond__c, User__c
                                                                   FROM Assignment_Groups__r
                                                                   WHERE Active__c = 'True' AND User_Active__c = 'True')
                                                       FROM Assignment_Group_Name__c 
                                                       WHERE  RecordTypeId=:inqPartnerRecordTypeId]);
            System.debug('assignmentGroupPartner-2->'+[SELECT Id, ( SELECT Id, Last_Assignment__c, Millisecond__c, User__c
                                                                   FROM Assignment_Groups__r
                                                                   WHERE Active__c = 'True' AND User_Active__c = 'True')
                                                       FROM Assignment_Group_Name__c 
                                                       WHERE  RecordTypeId=:inqPartnerRecordTypeId]);*/
            for(Assignment_Group_Name__c assignmentGroup : [SELECT Id, ( SELECT Id, Last_Assignment__c, Millisecond__c, User__c
                                                                        FROM Assignment_Groups__r
                                                                        WHERE Active__c = 'True' AND User_Active__c = 'True')
                                                            FROM Assignment_Group_Name__c
                                                            WHERE  RecordTypeId=:inqPartnerRecordTypeId]){
                                                                
                                                                System.debug('assignmentGroup===>'+assignmentGroup);
                                                                List<Assignment_Groups__c> sortedMembers = sortMemebersByLastAssignmentTime(assignmentGroup.Assignment_Groups__r);
                                                                groupIdToMembersMap.put(assignmentGroup.Id, sortedMembers);
                                                                
                                                            }
            
            List<Assignment_Group_Name__c> assignmentGroupNameList = new List<Assignment_Group_Name__c>();
            assignmentGroupNameList = [select id from Assignment_Group_Name__c where RecordTypeId=:inqPartnerRecordTypeId];
            List<Assignment_Groups__c> groupMemberList = new List<Assignment_Groups__c>();
            groupMemberList = [select Id, Last_Assignment__c, Millisecond__c, User__c from
                               Assignment_Groups__c where Group_Name__c IN :assignmentGroupNameList order by Last_Assignment__c asc];
            
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
                    if(!GroupMemberList.isEmpty()){
                        mql.OwnerId = groupMemberList[0].User__c;
                        mql.Requires_MQL_Assignment__c = false;
                        Datetime now = Datetime.now();
                        groupMemberList[0].Last_Assignment__c = now;
                        groupMemberList[0].Millisecond__c = now.millisecondGMT();
                        groupMemberList = sortMemebersByLastAssignmentTime(groupMemberList); 
                    }
                }
            }
            update groupMemberList;
            update updateMembersMap.values();
        }catch(exception e){
            System.debug(' get Exception on linenumber-->'+e.getLineNumber()+' error -->'+e.getMessage() + ' stack trace-->'+e.getStackTraceString());
            // return null;
        }
        
        
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
    
    
    public static List<Assignment_Groups__c> sortMemebersByLastAssignmentTime(List<Assignment_Groups__c> members){
        List<Assignment_Groups__c> result = new List<Assignment_Groups__c>();
        if(members == null || members.isEmpty()) return result;
        
        for(integer i = 0; i < members.size(); i++){
            for(integer j = 0; j <  members.size() - 1 - i; j++){
                
                if(members[j].Last_Assignment__c == null) members[j].Last_Assignment__c = Datetime.newInstance(1970,1,1,0,0,0);
                if(members[j+1].Last_Assignment__c == null) members[j+1].Last_Assignment__c = Datetime.newInstance(1970,1,1,0,0,0);
                if(members[j].Last_Assignment__c.getTime() >= members[j + 1].Last_Assignment__c.getTime()){
                    Assignment_Groups__c temp = members[j];
                    members[j] = members[j+1];
                    members[j+1] = temp;
                }
            }
        }
        result = members;
        
        
        return result;
    }
    
    //Description: This method is to filter the record and set the record in the list.
    public static WrapperClassToFilterRecords filterRecords(List<FSR__c> newRecords){
        System.debug('newRecords----->'+newRecords);    
        WrapperClassToFilterRecords wrapperInstance  = new WrapperClassToFilterRecords();
        if(!newRecords.isEmpty()){
            Id consultingRecordTypeId = Schema.SObjectType.FSR__c.getRecordTypeInfosByName().get('Consulting').getRecordTypeId();
            Id technologyRecordTypeId = Schema.SObjectType.FSR__c.getRecordTypeInfosByName().get('Technology').getRecordTypeId();
            for(FSR__c fsr : newRecords){
                if(fsr.RecordTypeId == consultingRecordTypeId || fsr.RecordTypeId == technologyRecordTypeId || fsr.FSR_Record_Type__c == 'Consulting' || fsr.FSR_Record_Type__c == 'Technology'){
                    wrapperInstance.partnerRecordList.add(fsr);
                }
                else{
                    wrapperInstance.mqlRecordList.add(fsr);
                }
            }
            System.debug('wrapperInstance----->'+wrapperInstance);
        }
        return wrapperInstance;
    }
    
    //Description: Wrapper Class to filter new records. 
    public class WrapperClassToFilterRecords{
        //Description:This is the List of the records which has record type is Partner.
        public List<FSR__c> partnerRecordList=new List<FSR__c>();
        //Description:This is the List of the records which has record type is Other than Partner.
        public List<FSR__c> mqlRecordList=new List<FSR__c>();
    }
    
    
    
    
}