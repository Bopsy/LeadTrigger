public class RiskReportLCController {
	@AuraEnabled 
    public static List<String> getStakeholderList(Id recordId) {
        String clevel = '';
        List<CLevel_Email__c> clevelList = CLevel_Email__c.getall().values();
        for(CLevel_Email__c cEmail: clevelList) {
            clevel+=', '+cEmail.Name;
        }
        

        //String clevel = 'Marc Boroditsky, Glenn Weinstein'; //will replace by custom setting
        /***
         * Submitter: NAMER WEST AE: Jake Kanter
         * Tier 3 Manager: Luke, 
         * Tier 2 Director: Stevie case
         * Tier 1 VP&C level: Alyson, Marc, C+
         * ***/
        Case riskReport = [SELECT Account.OwnerID,Tier_Alert_Status__c, Severity_Level__c, ARR_at_Risk__c,Risk_Report_Age__c  
                           FROM Case 
                           WHERE id =: recordID LIMIT 1];
        User submitter = [SELECT manager.name, manager.manager.name, manager.manager.manager.name 
                          FROM User 
                          where ID =: riskReport.Account.OwnerID];//IN (SELECT createdbyID from case where id =: recordID) LIMIT 1];
        String manager = submitter.manager.name;
        String director = manager+', '+submitter.manager.manager.name;
        String vp = director+', '+submitter.manager.manager.manager.name + clevel;
        //if (submitter.manager.name != NULL) manager = submitter.manager.name;
        //if (submitter.manager.manager.name != NULL) director = manager+', '+submitter.manager.manager.name;
        //if (submitter.manager.manager.manager.name != NULL) vp = director+', '+submitter.manager.manager.manager.name + clevel;
        
        List<String> op = new List<String>();
        op.add(manager);
        op.add(director);
        op.add(vp);
        op.add(riskReport.Tier_Alert_Status__c);
        
        
        return op;
    }
    
    @AuraEnabled 
    public static String sendTierAlert(Id recordId, string selectedTier, string nameLst) {
        Set<String> mcs = CXTeam__c.getall().keySet();
        Boolean isCX = mcs.contains(UserInfo.getUserId());
        if(!isCX) return 'Only CX Team can send Tier Alert';
        
        Case riskReport = [SELECT Tier_Alert_Status__c ,status, Percent_of_ARR_at_Risk__c  FROM Case WHERE id =: recordID LIMIT 1];
        
        if(riskReport.Tier_Alert_Status__c == selectedTier) return selectedTier+' Alert email is already sent before';
        Boolean escalation = isEscalated(riskReport.Tier_Alert_Status__c, selectedTier);
        
        riskReport.Tier_Alert_Status__c = selectedTier;
        if(riskReport.status != 'Ongoing Risk' && riskReport.status != 'Working' ) return 'only Onging or Woring Risk can send Tier Alert';
        

        /***
        String clevel = '';1->3
        List<CLevel_Email__c> clevelList = CLevel_Email__c.getall().values();
        for(CLevel_Email__c cEmail: clevelList) {
            clevel+=', '+cEmail.Email__c;
        }***/
        
        List<String> stakeholders = nameLst.trim().split('\\s*,\\s*');
        List<User> userList = [select email from user where name in: stakeholders];
        
		List<String> stakeholdersEmail = new List<String>();
        for(User u: userList) {
            stakeholdersEmail.add(u.Email);
        }
        

        update riskReport;
        if(escalation) {
            sendEmailHelper(recordId,'RR Escalation Email to Stakeholders - V', stakeholdersEmail);
        } else {
        	sendEmailHelper(recordId,'RR Tier Email to Stakeholders - V', stakeholdersEmail);
        }
        
        
        return selectedTier+' alert email is successfully sent';
        
        
    }
    
    public static Boolean isEscalated(String currTier, String newTier) {
        if(currTier == 'Tier 3' && newTier != 'Tier 3') {
            return true;
        } else if(currTier == 'Tier 2' && newTier == 'Tier 1') {
            return true;
        }
        
        return false;
        
    }
    
    public static void sendEmailHelper(Id recordId, String emailTemplateName, List<String> emailList) {
        List<String> ccEmailList = new List <String>();
        Set<String> cxTeamID = CXTeam__c.getall().keySet();
        List<User> userList = [select email from user where ID in: cxTeamID];
        for(User u: userList) {
            ccEmailList.add(u.email);
        }
        
        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name =: emailTemplateName];
        
        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplate.ID, '0051W000005a8ry', recordId);

        String emailSubject = email.getSubject();
        String emailTextBody = email.getPlainTextBody();
        
        email.setSubject(emailSubject);
        email.setPlainTextBody(emailTextBody);
        email.saveAsActivity = false;
        email.setToAddresses(emailList);
        email.setCcAddresses(ccEmailList);


		Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        
    }
    
    
    
    
    
    
}