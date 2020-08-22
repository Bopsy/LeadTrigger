/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  CTAInfluenceServices
*
* @description 	  Service class that contains the logic to update CTA influence on the Opportunity and Risk Report.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	 <jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2018-11-13
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public with sharing class CTAInfluenceServices {
    //private static final Integer intDateRange = 14; /*14-day CTA Influence Range*/
    
	public static List<Opportunity> getOpportunityInfluence(List<Account> acctRecs, Integer intRange){
        Map<Id, Account> acctMap = new Map<Id, Account>(acctRecs);
        List<Opportunity> oppsForUpdate = new List<Opportunity>();
        List<Opportunity> oppsForReview = getRelatedOpportunities(acctMap);
        
        if(!oppsForReview.isEmpty()){
            //How to loop through child records
            for(Opportunity o : oppsForReview){
                Account tempAccount = acctMap.get(o.AccountId);
                for(JBCXM__CTA__c childCTA : tempAccount.JBCXM__Account__r){
                    Integer dateDiff = getDateTimeDiffInDays(childCTA.CreatedDate, o.CreatedDate);
                    
                    if(o.CreatedDate > childCTA.CreatedDate && dateDiff <= intRange){
                        o.Related_CTA__c = childCTA.Id;
                        oppsForUpdate.add(o);
                        break;
                    }
                }
            }
        }
        
        return oppsForUpdate;
    }
    
    public static List<Risk__c> getRiskReportInfluence(List<Account> acctRecs, Integer intRange){
        Map<Id, Account> acctMap = new Map<Id, Account>(acctRecs);
        List<Risk__c> risksForUpdate = new List<Risk__c>();
        List<Risk__c> risksForReview = getRelatedRiskReports(acctMap);
        
        if(!risksForReview.isEmpty()){
            //How to loop through child records
            for(Risk__c r : risksForReview){
                Account tempAccount = acctMap.get(r.Account__c);
                
                for(JBCXM__CTA__c childCTA : tempAccount.JBCXM__Account__r){
                    Integer dateDiff = getDateTimeDiffInDays(childCTA.CreatedDate, r.CreatedDate);
                    
                    //Check to see if you should relate the CTA based on 2 week comparison.
                    if(r.CreatedDate > childCTA.CreatedDate && dateDiff <= intRange){
                        r.Related_CTA__c = childCTA.Id;
                        risksForUpdate.add(r);
                        break;
                    }
                }
            }
        }
        
        return risksForUpdate;
    }
    
    private static List<Opportunity> getRelatedOpportunities(Map<Id, Account> accts){
        List<Opportunity> oppsForReview = new List<Opportunity>();
        oppsForReview = [SELECT Id,
                                CreatedDate,
                                AccountId
                         FROM Opportunity
                         WHERE AccountId in :accts.keySet()
                        	AND Related_CTA__c = null];
        return oppsForReview;
    }
    
    private static List<Risk__c> getRelatedRiskReports(Map<Id, Account> accts){
        List<Risk__c> riskReportsForReview = new List<Risk__c>();
        riskReportsForReview = [SELECT Id,
                                	   CreatedDate,
                                	   Account__c
                         		FROM Risk__c
                         		WHERE Account__c in :accts.keySet()
                        			AND Related_CTA__c = null];
        return riskReportsForReview;
    }
    
    public static Integer getDateTimeDiffInDays(DateTime beginningDate, DateTime endDate){
        Integer i;
        
        Long beginningDateMS = beginningDate.getTime();
        Long endDateMS = endDate.getTime();
        Long msDiff = endDateMS - beginningDateMS;
        Long days = msDiff / 1000 /*Milliseconds*/ / 60 /*Seconds*/ / 60 /*Minutes*/ / 24 /*Hours*/;
        i = Integer.valueOf(days);
        
        return i;
    }
    
    public static List<CTA_Digest__c> getCTADigestList(List<JBCXM__CTA__c> ctaList, Date startDate, Date endDate){
        List<CTA_Digest__c> ctaDigests = new List<CTA_Digest__c>();
        Set<Id> userIds = new Set<Id>();
    	for(JBCXM__CTA__c ctaRec : ctaList){
            userIds.add(ctaRec.JBCXM__Assignee__c);
        }
        
        for(Id userId : userIds){
            CTA_Digest__c ctaDig = new CTA_Digest__c(OwnerId = userId,
                                                     Digest_Start_Date__c  = startDate,
                                                     Digest_End_Date__c = endDate);
            ctaDigests.add(ctaDig);
            //userToDigestMap.put(userId, ctaDig);
        }
        
        return ctaDigests;
    }
    
    public static Map<CTA_Digest__c, List<JBCXM__CTA__c>> getCTADigestMap(List<CTA_Digest__c> ctaDigestList, List<JBCXM__CTA__c> ctaList){
        Map<Id, CTA_Digest__c> userToDigestMap = new Map<Id, CTA_Digest__c>();
        Map<CTA_Digest__c, List<JBCXM__CTA__c>> ctaDigestToCTAMap = new Map<CTA_Digest__c, List<JBCXM__CTA__c>>();
        
        List<Id> ctaDigestIds = new List<Id>(new Map<Id, CTA_Digest__c>(ctaDigestList).keyset());
        
        List<CTA_Digest__c> updatedDigests = [SELECT Id, 
                                                     Digest_Start_Date__c, 
                                                     Digest_End_Date__c,
                                             		 OwnerId,
                                             		 Owner.Email,
                                               		 Owner.FirstName
                                              FROM CTA_Digest__c
                                              WHERE Id IN :ctaDigestIds];
        for(CTA_Digest__c ctaDig : updatedDigests/*ctaDigestList*/){
            userToDigestMap.put(ctaDig.OwnerId, ctaDig);
        }
        
        for(JBCXM__CTA__c ctaRec : ctaList){
            List<JBCXM__CTA__c> tempList = new List<JBCXM__CTA__c>();
            CTA_Digest__c tempDigest = new CTA_Digest__c();
            tempDigest = userToDigestMap.get(ctaRec.JBCXM__Assignee__c);
            
            //Also update CTA
            ctaRec.CTA_Digest__c = tempDigest.Id;
            
            if(ctaDigestToCTAMap.get(tempDigest) != null){
                tempList = ctaDigestToCTAMap.get(tempDigest);
            }
            tempList.add(ctaRec);
            ctaDigestToCTAMap.put(tempDigest, tempList);
            
            
            //ctasForUpdate.add(ctaRec);
        }
        return ctaDigestToCTAMap;
    }
    
    public static List<JBCXM__CTA__c> getAllCTAsFromMap(Map<CTA_Digest__c, List<JBCXM__CTA__c>> ctaDigestToCTAMap){
        List<JBCXM__CTA__c> allCTAs = new List<JBCXM__CTA__c>();
        
        for(CTA_Digest__c ctaDig : ctaDigestToCTAMap.keySet()){
            allCTAs.addAll(ctaDigestToCTAMap.get(ctaDig));
        }
        
        return allCTAs;
    }
    
    public static List<Messaging.SingleEmailMessage> getAllCTADigestEmails(Map<CTA_Digest__c, List<JBCXM__CTA__c>> ctaDigestToCTAMap){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Boolean isProductionOrg = IsProductionOrg();
        
        for(CTA_Digest__c ctaDig : ctaDigestToCTAMap.keySet()){
            Messaging.SingleEmailMessage email = getCTADigestEmailTemplate(ctaDig);
            String tempTableBody = getTableBody(ctaDig, ctaDigestToCTAMap.get(ctaDig), isProductionOrg);
            
            email.setHtmlBody(tempTableBody);
            emails.add(email);
        }
        
        return emails;
    }
    public static Messaging.SingleEmailMessage getCTADigestEmailTemplate(CTA_Digest__c ctaDig){
        string toMail = ctaDig.Owner.Email;
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        string[] to = new string[] {toMail};
        string[] bcc = new string[] {'jayu@twilio.com', 'npotter@twilio.com', 'pli@twilio.com'};
        
        if(toMail == null || tomail == ''){
        	email.setToAddresses(bcc);
        } else {
            email.setToAddresses(to);
            email.setBccAddresses(bcc);
        }
        
        email.setSenderDisplayName('Customer Insight Alert System');
        email.setReplyTo('salesops@twilio.com');
        email.setSubject('Insight Alerts: Top Account Activities ' + String.valueOf(ctaDig.Digest_Start_Date__c) + ' to ' + 
                         String.valueOf(ctaDig.Digest_End_Date__c));
        
        return email;
    }
    
    public static String getTableBody(CTA_Digest__c ctaDigest, List<JBCXM__CTA__c> ctaList, Boolean isProductionOrg){
        String htmlBody = 'Ahoy, ' + ctaDigest.Owner.FirstName + '!<br><br>Here are some important activities ' +
            'in your Accounts that you\'ll want to check out:<br><br><center><font size="4"><b>Usage Growth CTAs</b></font></center>';
        String htmlThumbsUp = '';
        String htmlThumbsDown = '';
        String wasThisHelpful = '<br><center><b>Was this week\'s CIA Digest helpful?</b></center>';
    
        //open table..
        String baseURL = '';
        if(isProductionOrg == TRUE){
            baseURL = CTADigestURL__c.getValues('Production Site').URL__c;
        } else {
            baseURL = CTADigestURL__c.getValues('Full Sandbox Site').URL__c;
        }
        
        String Url = System.URL.getSalesforceBaseUrl().toExternalForm();
        String urlIsHelpful = baseURL + '?id=' + ctaDigest.Id + '&isHelpful=Yes';
        String urlIsNotHelpful = baseURL + '?id=' + ctaDigest.Id + '&isHelpful=No';
        String thumbsUpIMGBB = CTADigestURL__c.getValues('ThumbsUp').URL__c;//'https://i.ibb.co/wMpQ5z3/ThumbsUp.png';
        String thumbsDownIMGBB = CTADigestURL__c.getValues('ThumbsDown').URL__c;//'https://i.ibb.co/w710zFc/Thumbs-Down.png';
        String testTableCaption = 'test1234';
        //open table..
        
        htmlBody += '<center><table border="1" style="border-collapse: collapse"><caption>'/*+ testTableCaption*/ + '</caption><tr><th>Customer Insight Alert</th><th>Account</th>' +
            '<th>Created Date</th><th>Assignee Name</th></tr>'; 
        htmlThumbsUp = '<a href="' + urlIsHelpful +'"><img src="' + thumbsUpIMGBB + '" style="width:77px; height:81px" title="ThumbsUp"></a>';
        htmlThumbsDown = '<a href="' + urlIsNotHelpful + '"><img src="' + thumbsDownIMGBB + '" style="width:77px; height:81px" title="ThumbsDown"></a>';
        
        //iterate over list and output columns/data into table rows...
        for(JBCXM__CTA__c ctaRec : ctaList){
            String myLink = url + '/' + ctaRec.Id;
            
            String myAssigneeName = '';
            if(ctaRec.JBCXM__Assignee__r.Name != null){
                myAssigneeName = ctaRec.JBCXM__Assignee__r.Name;
            }
            String myAccountName = '';
            if(ctaRec.JBCXM__Account__r.Name != null){
                myAccountName = ctaRec.JBCXM__Account__r.Name;
            }
            //String myCTAName = ctaRec.Name;
            String myCTAName = ''; 
            if(ctaRec.Name != null){
                myCTAName = '<a href="' + myLink + '">' + ctaRec.Name + '</a>';
            }  
            /*
            String myCTAStatus = '';
            if(ctaRec.CTA_Status__c != null){
                myCTAStatus = ctaRec.CTA_Status__c; 
            }
			*/
            String myCTACreatedDate = '';
            if(ctaRec.JBCXM__CreatedDate__c != null){
                myCTACreatedDate = String.valueOf(ctaRec.JBCXM__CreatedDate__c); 
            }
            /*
            String myCTADueDate = '';
            if(ctaRec.JBCXM__DueDate__c != null){
                myCTADueDate = String.valueOf(ctaRec.JBCXM__DueDate__c); 
            }
            
            htmlBody += '<tr><td>' + myCTAName + '</td><td>' + myAccountName + '</td><td>' + myCTAStatus + '</td>' +
                '<td>' + myCTACreatedDate + '</td><td>' + myCTADueDate + '</td><td>' + myAssigneeName + 
                '</td></tr>';*/
            
            htmlBody += '<tr><td>' + myCTAName + '</td><td>' + myAccountName + '</td><td>' + myCTACreatedDate +
                '</td><td>' + myAssigneeName + '</td></tr>';
            
        }
		
    
        //close table...
        
        htmlBody += '</table></center><center>' + wasThisHelpful + htmlThumbsUp + '&emsp;&emsp;' + htmlThumbsDown + '</center>';
    
        return htmlBody;
    
    }
    
	public static Boolean IsProductionOrg() { // Method to check of environement is Production ORG or not
        Organization org = [select IsSandbox from Organization where Id =:UserInfo.getOrganizationId()];
        return (org.IsSandbox == true) ? false : true;
    }
	
    public static List<CTA_Digest__c> getNewDigestRecords(List<CTA_Digest__c> newDigests){
        return new List<CTA_Digest__c>([SELECT Id, 
                                               OwnerId, 
                                        	   Owner.Name,
                                        	   Owner.FirstName,
                                        	   Owner_Name__c,
                                        	   Digest_End_Date__c,
                                        	   Digest_Start_Date__c
                                        FROM CTA_Digest__c 
                                        WHERE Id in :newDigests]);
    }
}