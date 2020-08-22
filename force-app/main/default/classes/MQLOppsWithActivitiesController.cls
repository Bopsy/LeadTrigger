public class MQLOppsWithActivitiesController {
    
    public FSR__c mql;
    public List<Opportunity> lstOpps;
    public List<ActivityWrapper> ContActivities;
    public List<ActivityWrapper> AcctActivities;
    public Boolean relatedToLead { get { return (mql!=null && mql.Lead__c!=null); }}
    public Boolean relatedToContact { get { return (mql!=null && mql.Contact__c!=null); }}
    public Id relatedToId {get;set;}
    public String relatedToName {get;set;}
    public Id relatedToConId {get;set;}
    public String relatedToConName {get;set;}
    public Integer maxSearchResults = 50;
    public List<ActivityRecord> lstSetController1{get;set;}
    public List<ActivityRecord> lstSetController2{get;set;}
    MQLOppsWithActivitiesIterable acntSetCntrl;
    MQLOppsWithActivitiesIterable contSetCntrl;
    
    public ApexPages.StandardSetController con {
        get {
            if(con == null) {
                con = new ApexPages.StandardSetController(Database.getQueryLocator([Select Id,AccountId,Name,StageName,eARR__c ,CloseDate,Owner.Id, Owner.name, createdDate from Opportunity
                                                                                    where AccountId=:mql.Contact__r.AccountId order by isclosed ,CloseDate desc]));
                // sets the number of records in each page set
                con.setPageSize(5);
            }
            return con;
        }
        set;
    }
    
    public class ActivityWrapper implements Comparable {
        private ActivityRecord a;
        public ActivityWrapper(ActivityRecord a) {this.a = a;}
        public Integer compareTo(Object compareTo) {
            ActivityWrapper ctA = (ActivityWrapper) compareTo;
            if (this.a.ActivityDate ==null) return 1;
            if (ctA.a.ActivityDate < this.a.ActivityDate) return -1;
            if (ctA.a.ActivityDate > this.a.ActivityDate) return 1;
            return 0; 
        }
    }
    
    public MQLOppsWithActivitiesController(ApexPages.StandardController controller) {  
        // Need to add all of the fields so that they will be needed from the MQL (FSR__c) record
        List<String> fieldList = new List<String>();
        fieldList.add('Contact__c');
        fieldList.add('Lead__c');
        if (!Test.isRunningTest()) {
            controller.addFields(fieldList);
        }
        
        ContActivities = new List<ActivityWrapper>();
        mql= [Select Id, Contact__c,Contact__r.AccountId,Lead__c from FSR__c where Id=: controller.getRecord().Id limit 1];
        AcctActivities = new List<ActivityWrapper>();
        
        lstSetController1 = new List<ActivityRecord>();
        contSetCntrl = new MQLOppsWithActivitiesIterable (getContActivities()); 
        contSetCntrl.setPageSize = 5;
        next1();

        lstSetController2 = new List<ActivityRecord>();
        acntSetCntrl = new MQLOppsWithActivitiesIterable (getAcctActivities()); 
        acntSetCntrl.setPageSize = 5;
        next2();   
    }
    
    public List<Opportunity> getlstOpps(){
        lstOpps= (List<Opportunity>)con.getRecords();
        return lstOpps;
    }
    
    public List<ActivityRecord> getContActivities(){
        ContActivities = new List<ActivityWrapper>();
        Contact objCon = new Contact();
        Lead objLead = new Lead();
        if (relatedToContact || relatedToLead) {
            if(relatedToContact){
                objCon = [SELECT Id, Name,(SELECT Id, ActivityDate , Subject, Description, IsTask, Status, OwnerId, Owner.Name, LastModifiedDate, CreatedDate
                                           FROM OpenActivities ORDER BY ActivityDate desc NULLS LAST LIMIT :maxSearchResults), 
                          (SELECT Id, ActivityDate , Subject, Description, IsTask, Status, OwnerId, Owner.Name, LastModifiedDate, CreatedDate
                           FROM ActivityHistories ORDER BY ActivityDate desc NULLS LAST LIMIT :maxSearchResults) FROM Contact WHERE Id = :mql.Contact__c limit 1]; 
                
            }
            if(relatedToLead){
                objLead =  [SELECT Id,Name, (SELECT Id, ActivityDate, Subject,whatId, Description, IsTask, Status, OwnerId, Owner.Name, LastModifiedDate, CreatedDate
                                             FROM OpenActivities ORDER BY ActivityDate desc NULLS LAST LIMIT :maxSearchResults), (
                                                 SELECT Id, ActivityDate, Subject,whatId, Description, IsTask, Status, OwnerId, Owner.Name, LastModifiedDate, CreatedDate
                                                 FROM ActivityHistories ORDER BY ActivityDate desc NULLS LAST LIMIT :maxSearchResults) FROM Lead WHERE Id = :mql.Lead__c limit 1];
            }
            
            if (objCon != null || objLead!=null) {
                SObject obj = relatedToContact ? (SObject) objCon : (SObject) objLead;
                relatedToConId = relatedToContact ? ((contact)obj).Id : ((Lead)obj).Id;
                relatedToConName = relatedToContact ?((contact)obj).Name : ((Lead)obj).Name;
                for (OpenActivity o : obj.getSObjects('OpenActivities')) {
                    ContActivities.add(new ActivityWrapper(new ActivityRecord (o)));
                }
                
                for (ActivityHistory h : obj.getSObjects('ActivityHistories')) {
                    ContActivities.add(new ActivityWrapper(new ActivityRecord (h)));
                }
                ContActivities.sort();
                system.debug('+++acc '+ContActivities);
            }
        }
        List<ActivityRecord> lsstr= new List<ActivityRecord> ();
        for(ActivityWrapper record : ContActivities) {
            lsstr.add(record.a);
        }
        return lsstr;
    }
    
    public List<ActivityRecord> getAcctActivities(){
        AcctActivities = new List<ActivityWrapper>();
        if (relatedToContact) {
            Account objAcct =[SELECT Id, Name,(
                SELECT Id, ActivityDate , Subject, Description, IsTask, Status, OwnerId, Owner.Name, LastModifiedDate, CreatedDate
                FROM OpenActivities ORDER BY ActivityDate desc NULLS LAST LIMIT :maxSearchResults), 
                              (SELECT Id, ActivityDate , Subject, Description, IsTask, Status, OwnerId, Owner.Name, LastModifiedDate, CreatedDate
                               FROM ActivityHistories ORDER BY ActivityDate desc NULLS LAST LIMIT :maxSearchResults)
                              FROM Account WHERE Id = :mql.Contact__r.AccountId limit 1];
            if (objAcct != null) {
                relatedToId = objAcct.Id ;
                relatedToName =  objAcct.Name;
                for (OpenActivity o : objAcct.getSObjects('OpenActivities')) {
                    AcctActivities.add(new ActivityWrapper(new ActivityRecord (o)));
                }
                
                for (ActivityHistory h : objAcct.getSObjects('ActivityHistories')) {
                    AcctActivities.add(new ActivityWrapper(new ActivityRecord (h)));
                }
                AcctActivities.sort();
                system.debug('+++acc '+AcctActivities);
            }
        }
        List<ActivityRecord> lsstr= new List<ActivityRecord> ();
        for(ActivityWrapper record : AcctActivities) {
            lsstr.add(record.a);
        }
        return lsstr;
    }
    
    public Boolean hasNext {
        get {
            return con.getHasNext();
        }
        set;
    }
    
    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return con.getHasPrevious();
        }
        set;
    }
    
    // returns the previous page of records
    public void previous() {
        con.previous();
    }
    
    // returns the next page of records
    public void next() {
        con.next();
    }
    
    public Boolean hasNext1 {
        get 
        {
            return contSetCntrl.hasNext();
        }
        set;
    }
    
    public Boolean hasPrevious1 {
        get 
        {
            return contSetCntrl.hasPrevious();
        }
        set;
    }
    
    public void next1() 
    {
        lstSetController1 = contSetCntrl.next();
    }
    
    public void previous1() 
    {
        lstSetController1 = contSetCntrl.previous();
    }
    
    public Boolean hasNext2 {
        get 
        {
            return acntSetCntrl.hasNext();
        }
        set;
    }
    
    public Boolean hasPrevious2 {
        get 
        {
            return acntSetCntrl.hasPrevious();
        }
        set;
    }
    
    public void next2() 
    {
        lstSetController2 = acntSetCntrl.next();
    }
    
    public void previous2() 
    {
        lstSetController2 = acntSetCntrl.previous();
    }
    
    public void first() {
        con.first();
    }
    
    public void first1() {
        lstSetController1 =contSetCntrl.first();
    }
    
    public void first2() {
        lstSetController2 =acntSetCntrl.first();
    }
    
    // returns the last page of records
    public void last() {
        con.last();
    }
    
    public void last1() {
        lstSetController1 =contSetCntrl.last();
    }
    
    public void last2() {
        lstSetController2 =acntSetCntrl.last();
    }
    
}