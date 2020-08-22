global class BatchShiftGroupMember implements Database.Batchable<SObject>, Schedulable {
    
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchShiftGroupMember());
    }
    
    global Database.queryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('SELECT Shift__c FROM Assignment_Groups__c');
    }
    
    global void execute(Database.BatchableContext bc, List<Assignment_Groups__c> members){
        List<Group_Member_Shift__c> settings = Group_Member_Shift__c.getAll().values();
        Integer nowHour = Datetime.now().hour();
        List<Assignment_Groups__c> updateMembers = new List<Assignment_Groups__c>();
        
        for(Assignment_Groups__c member: members){
            Integer diffHour = 9999999;
            Group_Member_Shift__c chosenSetting = null;
            for(Group_Member_Shift__c setting: settings){
                if(member.Shift__c == setting.Shift__c){
                    Integer settingDiff = nowHour - setting.TimeStamp__c.hour();
                    if(settingDiff < diffHour && settingDiff >= 0){
                        diffHour = settingDiff;
                        chosenSetting = setting; 
                    }
                }
            }
            if(chosenSetting != null){
                member.Active__c = chosenSetting.IsActive__c ? 'True' : 'False';
                updateMembers.add(member);
            }
        }
        
        system.debug(updateMembers);
        Database.update(updateMembers, false);
    }
    
    global void finish(Database.BatchableContext bc){
        
    }
}