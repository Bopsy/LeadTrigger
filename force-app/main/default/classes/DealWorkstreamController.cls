/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           DealWorkstreamController
*
* @description    controller class for WorkstreamComponent
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2019-03-15
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class DealWorkstreamController {
    public final Id parentId {get;set;}
    public List<WrapperClass> lstDealWorkstreamsWrap {get;set;}
    public Id objDealId {get;set;}
    public String label {get;set;}
    public String tableWidth {get;set;}
    public Boolean rightPanel {get;set;}
    public Boolean chatterPanel {get;set;}
    public Deal_Workstream__c objDealWorkstream {get;set;}
    public Boolean displayDealworkstream {get;set;}
    public String sortDirection {get;set;}
    public static String sortBy='DESC';
    public String reducedTableWidth= '52%';
    public List<feedItem> lstChatterFeeds {get;set;}
    public Boolean showContent { get; set; }
    public Map<Id,Deal_Workstream__c> mapWorkstream {get;set;}
    public String sortByType {get;set;}
    public Workstream_Rollup_Mapping__c parentSetting{get;set;}
    public String objectName;
    
    public Boolean isPilot {get;set;}
    public Boolean isRiskReport {get;set;}
    public Boolean isCXTeam {get;set;}
    public Boolean isEditPage {get;set;}
    
    public DealWorkstreamController(ApexPages.StandardController stdController) {
        parentId  = ApexPages.CurrentPage().getparameters().get('id');
        
        String keyCode  = ((String) parentId).subString(0,3);
        isRiskReport = False;
        isPilot = false;
        
        if(keyCode == '500') {
            Case currCase = [SELECT recordtype.DeveloperName, isPilotGroup__c  FROM Case WHERE id =: parentID LIMIT 1];
            if(currCase.recordtype.DeveloperName == 'Risk_Report') {
                isRiskReport = true;
                if(currCase.isPilotGroup__c) {
                    isPilot = True;
                }
            }
        }
    }

    public DealWorkstreamController(){
        parentId  = ApexPages.CurrentPage().getparameters().get('id');
        String keyCode  = ((String) parentId).subString(0,3);
        isRiskReport = False;
        isPilot = false;
        isCXTeam = false;
        isEditPage = True;
        
        if(keyCode == '500') {
            Case currCase = [SELECT recordtype.DeveloperName, isPilotGroup__c  FROM Case WHERE id =: parentID LIMIT 1];
            if(currCase.recordtype.DeveloperName == 'Risk_Report') {
                isRiskReport = true;
                if(currCase.isPilotGroup__c) {
                    isPilot = True;
                    Set<String> mcs = CXTeam__c.getall().keySet();
        			isCXTeam = mcs.contains(UserInfo.getUserId());
                }
            }
        }

        
        
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for(Schema.SObjectType objectInstance : gd.values())
        {
            if(objectInstance.getDescribe().getKeyPrefix() == keyCode)
            {
                System.debug('Id is related to object: '+ objectInstance.getDescribe().getName());
                for(Workstream_Rollup_Mapping__c setting : Workstream_Rollup_Mapping__c.getAll().values()){
                    if(setting.Parent_Object_API_Name__c ==objectInstance.getDescribe().getName()){
                        objectName = setting.Parent_Lookup_API_Field__c ;
                    }
                }
                break;
            }
        }
        tableWidth=UserInfo.getUiThemeDisplayed()=='Theme3'? '65%' : '78%';
        rightPanel=false;
        chatterPanel=false;
        getDealWorkstreams();
        displayDealworkstream= true;
        sortDirection ='DESC';
        showContent=false;
    }
    
    public Attachment file;
    public Attachment getfile(){
        file = new Attachment();
        return file;
    }

    
    public void sortTable()
    {  
        sortBy = (sortDirection =='DESC') ? 'ASC' : 'DESC';
        getDealWorkstreams();
        sortDirection = sortBy;
    }
    
    public void refreshTable(){
        displayDealworkstream= true;
        rightPanel=false;
        chatterPanel=false;
        tableWidth=UserInfo.getUiThemeDisplayed()=='Theme3'? '65%' : '78%';
        sortBy = sortDirection;
        getDealWorkstreams();
        objDealId=null;
        showContent=false;
    }
    
    public PageReference refreshCaseTable(){
        refreshTable();
        return new PageReference('/apex/WorkstreamCasePage');
    }
    
    public void chatterDisplay(){
        tableWidth=reducedTableWidth;
        chatterPanel=true;
        rightPanel=false;
    }
    
    public void updateDealWorkstream() {
        
        Deal_Workstream__c objDealWorkstreams =  [SELECT Id, Name, CreatedDate ,Status__c FROM Deal_Workstream__c where Id=:objDealId];
        //Added by Davis - May 15
        WrapperClass dealWrap = null;
        for(WrapperClass objWrap : lstDealWorkstreamsWrap){
            if(objWrap.objDealWorkstream.Id == objDealId){
                dealWrap = objWrap;
                break;
            }
        }
        if(label=='Accept' || label=='Reopen'){
            objDealWorkstreams.Status__c = System.Label.In_Progress_status_value;
            dealWrap.isAccept = false;
            dealWrap.isComplete = true;
            dealWrap.isReopen = false;
            dealWrap.timeElapsed = 0;
            dealWrap.color = System.Label.In_Progress_status;
            dealWrap.unit = 'hrs';
            dealWrap.objDealWorkstream.Status__c = System.Label.In_Progress_status_value;
        }else if(label=='Complete'){
            objDealWorkstreams.Status__c = System.Label.Complete_status_value;
            dealWrap.isAccept = false;
            dealWrap.isComplete = false;
            dealWrap.isReopen = true;
            Long milliseconds = Datetime.now().getTime() - objDealWorkstreams.createdDate.getTime();
            if(milliseconds!=null){
                Long seconds = milliseconds / 1000;
                Long minutes = seconds / 60;
                Long hours = minutes / 60;
                Long days = hours / 24;
                dealWrap.timeElapsed = Integer.valueof(days==0 ? hours : days);
                dealWrap.unit = days==0 ? 'hrs' : 'days';
            }
            dealWrap.color = System.Label.Complete_status;
            dealWrap.objDealWorkstream.Status__c = System.Label.Complete_status_value;
        }else if(label=='Review'){
            objDealWorkstreams.Status__c = System.Label.Customer_Review_status_value;
            dealWrap.isAccept = false;
            dealWrap.isComplete = false;
            dealWrap.isReopen = true;
            
            dealWrap.timeElapsed = 0;
            dealWrap.color = System.Label.Complete_status;
            dealWrap.unit = 'hrs';
            dealWrap.objDealWorkstream.Status__c = System.Label.Customer_Review_status_value;
        }
        try{
            update objDealWorkstreams;
            //refreshTable(); 
        }catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
    
    public void updateRiskWorkstream() {

        Deal_Workstream__c objDealWorkstreams =  [SELECT Id, Name, OwnerId,CreatedDate ,Status__c FROM Deal_Workstream__c where Id=:objDealId];
        
        Set<String> mcs = CXTeam__c.getall().keySet();
            if(objDealWorkstreams.Id!=null && UserInfo.getUserId() != objDealWorkstreams.OwnerId && !mcs.contains(UserInfo.getUserId())) {
                return;
            }
        
        //Added by Davis - May 15
        WrapperClass dealWrap = null;
        for(WrapperClass objWrap : lstDealWorkstreamsWrap){
            if(objWrap.objDealWorkstream.Id == objDealId){
                dealWrap = objWrap;
                break;
            }
        }
        if(label=='Accept' || label=='Reopen'){
            objDealWorkstreams.Status__c = System.Label.In_Progress_status_value;
            dealWrap.isAccept = false;
            dealWrap.isReview = true;
            dealWrap.isComplete = true;
            dealWrap.isReopen = false;
            dealWrap.timeElapsed = 0;
            dealWrap.color = System.Label.In_Progress_status;
            dealWrap.unit = 'hrs';
            dealWrap.objDealWorkstream.Status__c = System.Label.In_Progress_status_value;
        }else if(label=='Complete'){
            objDealWorkstreams.Status__c = System.Label.Complete_status_value;
            dealWrap.isAccept = false;
            dealWrap.isComplete = false;
            dealWrap.isReview = false;
            dealWrap.isReopen = true;
            Long milliseconds = Datetime.now().getTime() - objDealWorkstreams.createdDate.getTime();
            if(milliseconds!=null){
                Long seconds = milliseconds / 1000;
                Long minutes = seconds / 60;
                Long hours = minutes / 60;
                Long days = hours / 24;
                dealWrap.timeElapsed = Integer.valueof(days==0 ? hours : days);
                dealWrap.unit = days==0 ? 'hrs' : 'days';
            }
            dealWrap.color = System.Label.Complete_status;
            dealWrap.objDealWorkstream.Status__c = System.Label.Complete_status_value;
        }else if(label=='Review'){
            objDealWorkstreams.Status__c = System.Label.Customer_Review_status_value;
            dealWrap.isAccept = false;
            dealWrap.isComplete = true;
            dealWrap.isReopen = false;
            dealWrap.isReview = false;
            dealWrap.timeElapsed = 0;
            dealWrap.color = System.Label.Complete_status;
            dealWrap.unit = 'hrs';
            dealWrap.objDealWorkstream.Status__c = System.Label.Customer_Review_status_value;
        }
        try{
            update objDealWorkstreams;
        }catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }

        
    }
    
    public PageReference saveCaseWorkstream() {
        try{
      		Set<String> mcs = CXTeam__c.getall().keySet();
            if(objDealWorkstream.Id==null && objDealWorkstream.Status__c==System.Label.Complete_status_value){
                objDealWorkstream.status__c.addError(System.Label.Deal_Workstream_Status );
				return null;
            }else if(objDealWorkstream.Id!=null && UserInfo.getUserId() != objDealWorkstream.OwnerId && !mcs.contains(UserInfo.getUserId())) {
                objDealWorkstream.addError('Only the Workstream owner and CX team can edit the workstream');
				return null;
            }else{
                upsert objDealWorkstream;
                refreshTable();
                if(file.name != null && file.body != null) {
                    Attachment attach = new Attachment(
                                        parentid = objDealWorkstream.ID,
                                        name = file.name,
                                        body = file.body);
                    insert attach;
                }
                
                return new PageReference('/apex/WorkstreamCasePage');
            }
        }catch(Exception e) {
            return new PageReference('/apex/WorkstreamCasePage');
        }

    }
    
    public void saveDealWorkstream() {
        try{
            if(objDealWorkstream.Id==null && objDealWorkstream.Status__c==System.Label.Complete_status_value){
                objDealWorkstream.status__c.addError(System.Label.Deal_Workstream_Status );
            }else{
                upsert objDealWorkstream;
                refreshTable();
            }
        }catch(DmlException e) {
            ApexPages.addMessages(e);
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
    }
    
    public void editDealWorkstream() {
        tableWidth=reducedTableWidth;
        chatterPanel=false;
        rightPanel=true;
        objDealWorkstream = [SELECT Id,Status__c,Type__c,Sub_Type__c,Target_End_Date__c,Actual_Type__c,Contract_Ops_Owner__c,OwnerId,Owner.type, End_Date__c, Description_of_Work__c  
                             FROM Deal_Workstream__c where Id=:objDealId];
        isEditPage = False;
    }
    
    public List<String> getFileId() {
        List<String> fileId = new List<String>();
        List<Attachment> attachedFiles = [select Id from Attachment where parentId =:objDealId order By LastModifiedDate DESC ];
        if( attachedFiles != null && attachedFiles.size() > 0 ) {
        for (Attachment attch : attachedFiles) {   
            fileId.add(attch.Id);
            }      
        }
        return fileId;
            
    }

    
    public void createDealWorkstream() {
        tableWidth=reducedTableWidth;
        rightPanel=true;
        chatterPanel=false;
        objDealId=null;
        if(isRiskReport) {
            objDealWorkstream = new Deal_Workstream__c(RecordTypeId = '0121W000000YfHX');
        } else {
            objDealWorkstream = new Deal_Workstream__c();
        }
        objDealWorkstream.put(objectName,parentId);
    }
    
    public void getDealWorkstreams() {
        
        lstDealWorkstreamsWrap = new List<wrapperClass>();
        String queryString = 'SELECT Id, Name,Contract_Ops_Owner__r.Name,Target_End_Date__c,Owner.Name,owner.type,Start_Date__c, Review_Start_Date__c ,Total_Time__c , ' +
            				  'Customer_review_start_date__c,End_Date__c ,Status__c ,Type__c ,Sub_Type__c ,Actual_Type__c,CreatedDate,Pending_duration__c, Review_duration__c, Description_of_Work__c ' +
            				   'FROM Deal_Workstream__c where '+ objectName +'=:parentId';
        system.debug('++queryString '+queryString);
        List<Deal_Workstream__c> lstDealWorkstreams =  database.query(queryString);
        
        if(lstDealWorkstreams != null && lstDealWorkstreams.size() > 0){
            for(Deal_Workstream__c  objDealWork : lstDealWorkstreams){
                WrapperClass wrapRecord = new WrapperClass();
                wrapRecord.objDealWorkstream = objDealWork; 
                wrapRecord.isAccept = objDealWork.Status__c == System.Label.Pending_status_value ? true : false;
                wrapRecord.isComplete = objDealWork.Status__c == System.Label.In_Progress_status_value ? true : false;
                wrapRecord.isReopen = (objDealWork.Status__c == System.Label.Complete_status_value || objDealWork.Status__c == System.Label.Customer_Review_status_value) ? true : false;
                Long milliseconds = null;
                if(wrapRecord.isAccept==true){
                    milliseconds = Datetime.now().getTime() - objDealWork.Start_Date__c.getTime();
                }
                if(wrapRecord.isComplete==true){
                    milliseconds = Datetime.now().getTime() - objDealWork.Review_Start_Date__c.getTime();
                }
                if(wrapRecord.isReopen==true){
                    if(objDealWork.Status__c == System.Label.Customer_Review_status_value){
                        milliseconds = Datetime.now().getTime() - objDealWork.Customer_review_start_date__c.getTime();
                    }
                }
                if(milliseconds!=null){
                    Long seconds = milliseconds / 1000;
                    Long minutes = seconds / 60;
                    Long hours = minutes / 60;
                    Long days = hours / 24;
                    wrapRecord.timeElapsed = Integer.valueof(days==0 ? hours : days);
                    wrapRecord.unit = days==0 ? 'hrs' : 'days';
                }
                if(objDealWork.Status__c == System.Label.Complete_status_value){
                    wrapRecord.timeElapsed = Integer.valueof(objDealWork.Total_Time__c);
                    wrapRecord.unit = 'days';
                }
                wrapRecord.color = objDealWork.Status__c == System.Label.Pending_status_value ? System.Label.Pending_status : 
                objDealWork.Status__c == System.Label.In_Progress_status_value ? System.Label.In_Progress_status : System.Label.Complete_status;
                lstDealWorkstreamsWrap.add(wrapRecord);
            }
            lstDealWorkstreamsWrap.sort();
            system.debug('+++lstDealWorkstreamsWrap '+lstDealWorkstreamsWrap);  
        }
    }   
    
    public void getChatterFeeds(){
        String sortorder = 'desc';
        lstChatterFeeds = new List<Feeditem>();
        if(sortByType=='Oldest First'){
            sortorder = 'asc';
        }
        String queryString = 'SELECT Id, Name,Contract_Ops_Owner__r.Name,Owner.Name,Start_Date__c,Target_End_Date__c, Review_Start_Date__c , Customer_review_start_date__c, ' +
            				  'End_Date__c ,Status__c ,Type__c ,Sub_Type__c ,Actual_Type__c,CreatedDate,Pending_duration__c, Review_duration__c, Description_of_Work__c ' +
            				   'FROM Deal_Workstream__c where '+ objectName +'=:parentId';
        List<Deal_Workstream__c> ws = database.query(queryString);
        mapWorkstream =  new Map<Id,Deal_Workstream__c>(ws);
        if(mapWorkstream.size()!=0){
            String idInClause = '(\'';
            for (Id ids : mapWorkstream.keySet()){
                idInClause += ids + '\',\'';
            }
            idInClause  = idInClause.substring(0,idInClause.length()-2);
            idInClause += ')';
            string querystr = 'SELECT InsertedById ,Body, parent.name, InsertedBy.name,Type,CommentCount,CreatedDate  ,(SELECT InsertedById ,InsertedBy.name,CommentBody,CreatedDate FROM FeedComments order by createddate) FROM FeedItem WHERE ParentId IN '+idInClause ;
            querystr +=  ' and type!= \'TrackedChange\' order by createddate ';
            querystr += sortorder ;
            system.debug('++=query '+querystr);
            lstChatterFeeds = database.query(querystr);
        }
    }
    
    public void toggleContent() {
        //If the showContent variable is true, set it to false, else, set it to true
        if(showContent){
            showContent = false;
        }
        else{
            showContent = true;
        }
    }
    
    public class WrapperClass implements Comparable{
        
        public Deal_Workstream__c objDealWorkstream {get; set;}
        public Integer timeElapsed {get; set;}
        public String unit {get; set;}
        public Boolean isAccept {get; set;}
        public Boolean isComplete {get; set;}
        public Boolean isReview {get; set;}
        public Boolean isReopen {get; set;}
        public String color {get;set;}
                
        public WrapperClass(){
            isAccept = false;
            isComplete = false;
            isReopen = false;
            isReview= false;
        }
        
        public Integer compareTo(Object compareTo) {
            WrapperClass compareItem = (WrapperClass)compareTo;
            Decimal compareToTime =null;
            Decimal thisTime =null;
            if(compareItem.timeElapsed!=null){
                compareToTime = compareItem.unit=='hrs'? (decimal.valueof(compareItem.timeElapsed)/24) : decimal.valueof(compareItem.timeElapsed);
            }
            if(this.timeElapsed!=null){
                thisTime = this.unit=='hrs'? (decimal.valueof(this.timeElapsed)/24) : decimal.valueof(this.timeElapsed);
            }
            if(sortBy=='DESC'){
                if (compareToTime==null) return -1;
                if (thisTime == compareToTime) return 0;
                if (thisTime > compareToTime) return -1;
                return 1;  
            }else if(sortBy=='ASC'){
                if (compareToTime==null) return 1;
                if (thisTime == compareToTime) return 0;
                if (thisTime > compareToTime) return 1;
                return -1;  
            }
            return 2;     
        }
    }
    
}