/**
 *  Class Name:   AgreementAttachmentController
 *  Purpose:      This controller is used by the AgreementAttachment visualforce page
 **/
global class AgreementAttachmentController {
    public Apttus__APTS_Agreement__c agreement { get; set; }
    public List<AttachmentWrapper> readOnlyAttachments { get; set; }
    public List<AttachmentWrapper> userAttachments { get; set; }
    public List<AttachmentWrapper> allAttachments {get; set;}
    public static Set<String> NEED_APPROVAL_STATUS = new Set<String>{'Not Started'};
    public static Set<String> REJECTED_STATUS = new Set<String>{'Rejected'};
    public final static string DOCUSIGN_READY = 'Docusign Ready';
    public final static string IN_APPROVAL = 'In Review';
    public final static string NEED_SUBMIT = 'Need Submit';
    public final static String REJECTED = 'Rejected';
    public String docusignOwner {get; set;}
    public String legalName {get; set;}
    public String legalEmail {get; set;}
    public Blob attachmentBody {get; set;}
    public String attachmentName {get; set;}
    public String reason {get; set;}
    public String reason2 {get; set;}
    public String detail {get; set;}
    public Boolean showPricingCheckbox {get; set;}
    public String selectedPricing {get; set;}
 
    public Attachment attachment { get {
      if (attachment == null) attachment = new Attachment();
      return attachment;
    } set; }

    public Id attachmentId { get; set; }
    public Id agreementAttachmentId { get; set; }

    public Boolean CanView   { get { return Schema.sObjectType.Agreement_Attachment__c.isAccessible(); } }
    public Boolean CanAdd    { get { return Schema.sObjectType.Agreement_Attachment__c.isCreateable(); } }
    public Boolean CanDelete { get { return Schema.sObjectType.Agreement_Attachment__c.isDeletable(); } }
    public Boolean HasAttachments { get { return (hasReadOnlyAttachments || hasUserAttachments); } }
    public Boolean HasReadOnlyAttachments { get { return (readOnlyAttachments != null && !readOnlyAttachments.isEmpty()); } }
    public Boolean HasUserAttachments { get { return (userAttachments != null && !userAttachments.isEmpty()); } }
    public Boolean HasAgreement { get { return (agreement != null && agreement.Id != null); } }
    public boolean displayPopup {get; set;}
    public boolean showUpload {get; set;}
    public Map<String, String> agreementFieldMapping {get; set;}
    public boolean sendDocuSign {get; set;}
    public boolean enableWordDoc {get;set;}
    public boolean allowEnableWordDoc {get;set;}
    
    public void closeUploadWindow() {        
        showUpload = false;    
    }     
    public void showUploadWindow() {        
        showUpload = true;    
    }
    
    public void closePopup() {        
        displayPopup = false;    
    }     
    public void showPopup() {        
        displayPopup = true;    
    }
    
    public AgreementAttachmentController(ApexPages.StandardController controller) {
        // Need to add all of the fields so that they will be needed
        List<String> fieldList = new List<String>();
        fieldList.add('Name');
        if (!Test.isRunningTest()) {
            controller.addFields(fieldList);
        }
        
        agreementFieldMapping = new Map<String, String>();
        
        for(Agreement_Attachment_Mapping__c fieldMap: Agreement_Attachment_Mapping__c.getAll().values()){
            agreementFieldMapping.put(fieldMap.Agreement_Field_Name__c, fieldMap.Attachment_Field_Name__c);
        }
        
        Id recordId = controller.getId();
        String queryString = 'SELECT ';
        queryString += String.join((new List<String>(agreementFieldMapping.keySet())), ', ');
        if(!agreementFieldMapping.isEmpty()) queryString += ', ';
        queryString += ' Id, Signatory_s_Name__c, Signatorys_Email__c, Standard_Pricing__c FROM Apttus__APTS_Agreement__c WHERE Id =: recordId LIMIT 1';
        agreement = (Apttus__APTS_Agreement__c) database.query(queryString);
        showPricingCheckbox = agreement.Standard_Pricing__c && Agreement_Standard_Pricing__c.getInstance().Upload_Standard_Pricing__c;
        selectedPricing = 'Yes';
        agreement.Standard_Pricing__c = false;
        legalName = agreement.Signatory_s_Name__c;
        legalEmail = agreement.Signatorys_Email__c;
        
        List<Agreement_Attachment__c> attachments = [SELECT Import_Reason_Detail__c, Import_Reason_Explanation__c, Reason_for_Import__c,Enable_Word_Download__c  
                                                     FROM Agreement_Attachment__c
                                                     WHERE Agreement__c =: recordId
                                                     ORDER BY CreatedDate DESC];
        if(attachments != null && !attachments.isEmpty()){
            reason = attachments[0].Reason_for_Import__c;
            reason2 = attachments[0].Import_Reason_Detail__c;
            detail = attachments[0].Import_Reason_Explanation__c;
        }
		// Initialize attachments list
		fetchAttachments();
        String userProfile = [Select Id,Name from Profile where Id=:userinfo.getProfileId()].Name;
        List<String> lstProfiles = new List<String>();
        for(Profiles_To_DwL_worddoc_attachments__c setting: Profiles_To_DwL_worddoc_attachments__c.getAll().values()){
                lstProfiles.add(setting.name);
        }
        if(lstProfiles.contains(userProfile)){
            allowEnableWordDoc=true;
        }else{
            allowEnableWordDoc=false;
        }
        enableWordDoc=false;
    }

	public void fetchAttachments() {
		//if (agreement == null || agreement.Id == null) {
        //	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Agreement not found'));
		//	return;
		//}

		// Read-only attachments related to the agreement (Apttus__APTS_Agreement__c).        
        readOnlyAttachments = new List<AttachmentWrapper>();
        List<Attachment> attachments = [SELECT Id, ParentId, Name, BodyLength, ContentType, OwnerId, Owner.Name, CreatedById, CreatedBy.Name, CreatedDate
            FROM Attachment
            WHERE ParentId = :agreement.Id
            ORDER BY LastModifiedDate DESC];
        Map<String, Id> attachmentChatterIds = new Map<String, Id>();
        
        for (Attachment a : attachments) {
                attachmentChatterIds.put(a.Id, null);
        }
        
        Map<Id, Agreement_Attachment__c> existingAttachmentId = new Map<Id, Agreement_Attachment__c>();
        
        for(Agreement_Attachment__c obj: [SELECT Id, Name, Agreement__r.Wet_Signatures_Needed__c, CreatedBy.Profile.Name, Send_To_Legal_Date_Time__c, Deal_Desk_Approved_By__c, Legal_Approved_By__c, Accounting_Approved_By__c, Attachment_Id__c,Docusign_Ready__c,Enable_Word_Download__c,Imported__c, Needs_Approval__c  FROM Agreement_Attachment__c WHERE Agreement__c =: agreement.Id]){
            if(obj.Attachment_Id__c != null) existingAttachmentId.put(obj.Attachment_Id__c, obj);
        }
        
        Boolean allowedProfileToDownload=false;
        String userProfile = [Select Id,Name from Profile where Id=:userinfo.getProfileId()].Name;
        List<String> lstProfiles = new List<String>();
        for(Profiles_To_DwL_worddoc_attachments__c setting: Profiles_To_DwL_worddoc_attachments__c.getAll().values()){
                lstProfiles.add(setting.name);
        }
        if(lstProfiles.contains(userProfile)){
            allowedProfileToDownload=true;
        }else{
            allowedProfileToDownload=false;
        }
        
        for (Attachment a : attachments) {
                AttachmentWrapper wrapper = new AttachmentWrapper(a);
                wrapper.canDelete = UserInfo.getUserId() == a.OwnerId;
                if(existingAttachmentId.containsKey(a.Id)){
                    wrapper.approvalStatus = DOCUSIGN_READY;
                    wrapper.accountStatus = 'Approved';
                    wrapper.dealDeskStatus = 'Approved';
                    wrapper.legalStatus = 'Approved';
                    wrapper.managerStatus = 'Approved';
                    wrapper.tier2ManagerStatus = 'Approved';
                    wrapper.commitStatus = 'Approved';
                    wrapper.specialTermStatus = 'Approved';
                    wrapper.contractOpsStatus = 'Approved';
                    wrapper.SGDDStatus = 'Approved';
                    wrapper.SGAcctStatus = 'Approved';
                    wrapper.SGLegalStatus = 'Approved';
                    wrapper.canAccess = true;
                    Agreement_Attachment__c obj = existingAttachmentId.get(a.Id);
                    wrapper.customObjId = obj.Id;
                    wrapper.canResubmit = obj.Send_To_Legal_Date_Time__c != null;
                    wrapper.canDelete = wrapper.canDelete && obj.Deal_Desk_Approved_By__c == null && obj.Legal_Approved_By__c == null && obj.Accounting_Approved_By__c == null;
                    if(obj.Agreement__r.Wet_Signatures_Needed__c){wrapper.canSubmit = false; wrapper.canResubmit = false;}
                    if(obj.Agreement__r.Wet_Signatures_Needed__c && obj.CreatedBy.Profile.Name.contains('Legal')){wrapper.approvalStatus = ''; wrapper.canSubmit = false; wrapper.canResubmit = false;}
                    if(obj.Name != null && (obj.Name.Contains('.doc')|| obj.Name.Contains('.pdf'))){wrapper.canSubmit = false; wrapper.canResubmit = false;}
                    if(obj.Name != null && obj.Name.Contains('.pdf') && obj.Docusign_Ready__c==false && obj.Needs_Approval__c==false){wrapper.canSubmit = true; wrapper.canResubmit = true;}
                    if(obj.Name != null && obj.Name.Contains('.doc') && obj.Docusign_Ready__c==false && obj.Imported__c==true && obj.Needs_Approval__c==false){wrapper.canSubmit = true; wrapper.canResubmit = true;}
                    if(obj.Name != null && obj.Name.contains('.doc') && obj.Enable_Word_Download__c==false){wrapper.canAccess = false;}
                    if(allowedProfileToDownload){wrapper.canAccess = true;}
                }
                wrapper.modifiedDate = a.CreatedDate;
                wrapper.lastModifiedDate = a.CreatedDate.format();
                if(attachmentChatterIds.get(a.Id) != null)
                    wrapper.chatterId = attachmentChatterIds.get(a.Id);
                readOnlyAttachments.add(wrapper);
        }

		// User attachments related to the Agreement_Attachment__c.        
        Map<Id,Agreement_Attachment__c> agreementAttachments = new Map<Id,Agreement_Attachment__c>([
        	SELECT Id, Name, SendGrid_Accounting_Approval_Status__c, SendGrid_Deal_Desk_Approval_Status__c, SendGrid_Legal_Approval_Status__c, Contract_Ops_Approval_Status__c, Agreement__r.Wet_Signatures_Needed__c, Overall_Special_Terms_Status__c, CreatedBy.Profile.Name, Deal_Desk_Approved_By__c, Accounting_Approved_By__c, Legal_Approved_By__c, Commit_Approval_Status__c, Legal_Approval_Status__c, X2nd_Tier_Manager_Approval_Status__c, Deal_Desk_Approval_Status__c, Manager_Approval_Status__c, Accounting_Approval_Status__c, Agreement__c, CreatedDate,
			Enable_Word_Download__c ,Docusign_Ready__c,Imported__c, Needs_Approval__c  FROM Agreement_Attachment__c
			WHERE Agreement__c = :agreement.Id
		]);

        userAttachments = new List<AttachmentWrapper>();
        for (Attachment a : [
            SELECT Id, ParentId, Name, BodyLength, ContentType, OwnerId, Owner.Name, CreatedById, CreatedBy.Name, LastModifiedDate
            FROM Attachment
            WHERE ParentId = :agreementAttachments.keySet()
            ORDER BY LastModifiedDate DESC
        ]) {
                AttachmentWrapper wrapper = new AttachmentWrapper(a);
                Agreement_Attachment__c obj = agreementAttachments.get(a.ParentId);
                wrapper.specialTermStatus = obj.Overall_Special_Terms_Status__c;
                wrapper.accountStatus = obj.Accounting_Approval_Status__c;
                wrapper.dealDeskStatus = obj.Deal_Desk_Approval_Status__c;
                wrapper.legalStatus = obj.Legal_Approval_Status__c;
                wrapper.managerStatus = obj.Manager_Approval_Status__c;
                wrapper.tier2ManagerStatus = obj.X2nd_Tier_Manager_Approval_Status__c;
                wrapper.commitStatus = obj.Commit_Approval_Status__c;
                wrapper.contractOpsStatus = obj.Contract_Ops_Approval_Status__c;
                wrapper.SGLegalStatus = obj.SendGrid_Legal_Approval_Status__c;
                wrapper.SGDDStatus = obj.SendGrid_Deal_Desk_Approval_Status__c;
                wrapper.SGAcctStatus = obj.SendGrid_Accounting_Approval_Status__c;
                wrapper.canDelete = UserInfo.getUserId() == a.OwnerId && obj.Deal_Desk_Approved_By__c == null && obj.Accounting_Approved_By__c == null && obj.Legal_Approved_By__c == null;
                wrapper.chatterId = obj.Id;
                wrapper.modifiedDate = obj.CreatedDate;
                wrapper.lastModifiedDate = obj.CreatedDate.format();
                wrapper.canResubmit = false;
                wrapper.canAccess = true;
                if(obj.Name != null && obj.Name.contains('.doc') && obj.Enable_Word_Download__c==false){wrapper.canAccess = false;}
                if(allowedProfileToDownload){wrapper.canAccess = true;}
                if((NEED_APPROVAL_STATUS.contains(wrapper.commitStatus) || NEED_APPROVAL_STATUS.contains(wrapper.managerStatus) || NEED_APPROVAL_STATUS.contains(wrapper.tier2ManagerStatus) ||
                    NEED_APPROVAL_STATUS.contains(wrapper.accountStatus) || NEED_APPROVAL_STATUS.contains(wrapper.dealDeskStatus) || NEED_APPROVAL_STATUS.contains(wrapper.legalStatus) || 
                    NEED_APPROVAL_STATUS.contains(wrapper.contractOpsStatus) || NEED_APPROVAL_STATUS.contains(wrapper.SGDDStatus))
                    && !(REJECTED_STATUS.contains(wrapper.commitStatus) || REJECTED_STATUS.contains(wrapper.contractOpsStatus) || REJECTED_STATUS.contains(wrapper.managerStatus) ||  REJECTED_STATUS.contains(wrapper.tier2ManagerStatus) || 
                         REJECTED_STATUS.contains(wrapper.accountStatus) || REJECTED_STATUS.contains(wrapper.dealDeskStatus) || REJECTED_STATUS.contains(wrapper.legalStatus) || wrapper.legalStatus == 'In Review' || wrapper.dealDeskStatus == 'In Review' || wrapper.accountStatus == 'In Review')
                         || REJECTED_STATUS.contains(wrapper.SGDDStatus)){
                    wrapper.canSubmit = true;
                    wrapper.approvalStatus = NEED_SUBMIT;
                }
                else if((REJECTED_STATUS.contains(wrapper.commitStatus) || REJECTED_STATUS.contains(wrapper.contractOpsStatus) || REJECTED_STATUS.contains(wrapper.managerStatus) || REJECTED_STATUS.contains(wrapper.tier2ManagerStatus) ||
                         REJECTED_STATUS.contains(wrapper.accountStatus) || REJECTED_STATUS.contains(wrapper.dealDeskStatus) || REJECTED_STATUS.contains(wrapper.legalStatus))
                         || REJECTED_STATUS.contains(wrapper.SGDDStatus)){
                    wrapper.canSubmit = false;
                    wrapper.approvalStatus = REJECTED;
                }
                else{
                    wrapper.canSubmit = false;
                    wrapper.approvalStatus = IN_APPROVAL;
                }
                if(obj.Agreement__r.Wet_Signatures_Needed__c && obj.CreatedBy.Profile.Name.contains('Legal')){wrapper.approvalStatus = ''; wrapper.canSubmit = false; wrapper.canResubmit = false;}
                if(obj.Name != null && (obj.Name.Contains('.doc') || obj.Name.Contains('.pdf'))){wrapper.canSubmit = false; wrapper.canResubmit = false;}
            	
                if(wrapper.approvalStatus != REJECTED && wrapper.approvalStatus != IN_APPROVAL){
                       if(obj.Name != null && obj.Name.Contains('.pdf') && obj.Docusign_Ready__c==false && obj.Needs_Approval__c==false){wrapper.canSubmit = true; wrapper.canResubmit = true;}
                       if(obj.Name != null && obj.Name.Contains('.doc') && obj.Docusign_Ready__c==false && obj.Imported__c==true && obj.Needs_Approval__c==false){wrapper.canSubmit = true; wrapper.canResubmit = true;}
                   }
                userAttachments.add(wrapper);
        }
        
        allAttachments = new List<AttachmentWrapper>();
        allAttachments.addAll(userAttachments);
        allAttachments.addAll(readOnlyAttachments);
        allAttachments.sort();
        
	}

	public PageReference upload() {
		Agreement_Attachment__c a = new Agreement_Attachment__c(Standard_Pricing__c = true, Name = attachmentName.left(80), Reason_for_Import__c = reason, Import_Reason_Detail__c = reason2, Import_Reason_Explanation__c = detail, Agreement__c = agreement.Id, Imported__c = true, Enable_Word_Download__c=enableWordDoc);
		
		for(String agreementField: agreementFieldMapping.keySet()){
            if(agreement.get(agreementField) != null){
                a.put(agreementFieldMapping.get(agreementField), agreement.get(agreementField));
            }
        }
        if(selectedPricing == 'Yes'){update new Apttus__APTS_Agreement__c(Id = agreement.Id, Standard_Pricing__c = false);a.Standard_Pricing__c = false;}
		insert a;
        
		attachment.OwnerId = UserInfo.getUserId();
		attachment.ParentId = a.Id; // the record the file is attached to
		attachment.Name = attachmentName;
		attachment.Body = attachmentBody;
		insert attachment;
	    
	    //if(a.Reason_for_Import__c == 'Twilio Countersignature Required'){a.Deal_Desk_Approval_Status__c = 'Approved';a.Accounting_Approval_Status__c = 'Approved';a.Legal_Approval_Status__c = 'Approved';a.Manager_Approval_Status__c = 'Approved';a.X2nd_Tier_Manager_Approval_Status__c='Approved';a.Commit_Approval_Status__c='Approved';a.Overall_Special_Terms_Status__c='Approved';update a;}
	    showUpload = false;
        fetchAttachments();
        attachment = null;
        //attachmentName = null;
        attachmentBody = null;
	    return ApexPages.currentPage();
	}

	public PageReference deleteAttachment() {
		System.debug('attachmentId = ' + attachmentId);
		System.debug('agreementAttachmentId = ' + agreementAttachmentId);
        if(agreementAttachmentId.getSobjectType() == Apttus__APTS_Agreement__c.SobjectType){
            Agreement_Attachment__c relatedRec = [SELECT Id FROM Agreement_Attachment__c WHERE Attachment_Id__c =: attachmentId LIMIT 1];
            delete relatedRec;
            delete new Attachment(Id = attachmentId);
        }
        else{
            delete new Agreement_Attachment__c(Id = agreementAttachmentId);
        }
		
		fetchAttachments();

		return null;
	}

    public PageReference submitAttachment(){
        Agreement_Attachment__c updateObject = new Agreement_Attachment__c(Id = agreementAttachmentId,  Needs_Approval__c = true, Docusign_Owner__c = docusignOwner, Docusign_Legal_Name__c = legalName, Docusign_Legal_Email__c = legalEmail);
        
        if(sendDocuSign != null && sendDocuSign == true){
            updateObject.Needs_Approval__c = false;
            updateObject.Send_To_Legal_Date_Time__c = DateTime.now();
        }
        Apttus__APTS_Agreement__c updateAgreement = new Apttus__APTS_Agreement__c(Id = agreement.Id);
        if(legalName != null) updateAgreement.Signatory_s_Name__c = legalName;
        if(legalEmail != null) updateAgreement.Signatorys_Email__c = legalEmail;
        
        List<Agreement_Attachment__c> updateObjects = new List<Agreement_Attachment__c>();
        updateObjects.add(updateObject);
        
        for(Agreement_Attachment__c agreement: [SELECT Total_Committed_Revenue__c, Manager_Approval_Status__c, Deal_Desk_Approval_Status__c, Accounting_Approval_Status__c, Legal_Approval_Status__c 
                                      FROM Agreement_Attachment__c 
                                      WHERE Agreement__c =: agreement.Id
                                      AND Id != :agreementAttachmentId]){
            if(agreement.Manager_Approval_Status__c == IN_APPROVAL) agreement.Manager_Approval_Status__c = 'Not Started';
            if(agreement.Deal_Desk_Approval_Status__c == IN_APPROVAL) agreement.Deal_Desk_Approval_Status__c = 'Not Started';
            if(agreement.Accounting_Approval_Status__c == IN_APPROVAL) agreement.Accounting_Approval_Status__c = 'Not Started';
            if(agreement.Legal_Approval_Status__c == IN_APPROVAL) agreement.Legal_Approval_Status__c = 'Not Started';
            agreement.Needs_Approval__c = false;
            updateObjects.add(agreement);
        }
        update updateObjects;
        update updateAgreement;
        fetchAttachments();
        displayPopup = false;
        return null;
    }
    public static String convertSize(Integer bytes) {
        Decimal d = Decimal.valueOf(bytes);
        if      (bytes>=1073741824) { return d.divide(1073741824,2)+' GB'; }
        else if (bytes>=1048576)    { return d.divide(1048576,2)+' MB'; }
        else if (bytes>=1024)       { return d.divide(1024,2)+' KB'; }
        else if (bytes>1)           { return bytes+' bytes'; }
        else if (bytes==1)          { return bytes+' byte'; }
        else                        { return '0 byte'; }
    }

    global class AttachmentWrapper implements Comparable {
        public Attachment Obj { get; set; }
        public Id Id { get; set; }
        public Id ParentId { get; set; }
        public Id customObjId {get; set;}
        public String Name { get; set; }
        public String Size { get; set; }
        public String ContentType { get; set; }
        public Id OwnerId { get; set; }
        public Id chatterId {get; set;}
        public String OwnerName { get; set; }
        public Id CreatedById { get; set; }
        public String CreatedByName { get; set; }
        public Boolean canSubmit {get; set;}
        public String dealDeskStatus {get; set;}
        public String accountStatus {get; set;}
        public String legalStatus {get; set;}
        public String managerStatus {get; set;}
        public String approvalStatus {get; set;}
        public String commitStatus {get; set;}
        public String contractOpsStatus {get; set;}
        public String tier2ManagerStatus {get; set;}
        public String lastModifiedDate {get; set;}
        public DateTime modifiedDate {get; set;}
        public Boolean canDelete {get; set;}
        public Boolean canResubmit {get; set;}
        public String specialTermStatus{get; set;}
        public String SGDDStatus{get; set;}
        public String SGAcctStatus{get; set;}
        public String SGLegalStatus{get; set;}
        public Boolean canAccess{get; set;}

        public AttachmentWrapper(Attachment a) {
            this.Obj = a;
            this.Id = a.Id;
            this.ParentId = a.ParentId;
            this.Name = a.Name;
            this.Size = convertSize(a.BodyLength);
            this.ContentType = a.ContentType;
            this.OwnerId = a.OwnerId;
            this.OwnerName = a.Owner.Name;
            this.CreatedById = a.CreatedById;
            this.CreatedByName = a.CreatedBy.Name;
            this.canSubmit = false;
            this.canAccess = true;
        }
        
        global Integer compareTo(Object compareTo){
            AttachmentWrapper compareWrapper = (AttachmentWrapper) compareTo;
            if(modifiedDate == compareWrapper.modifiedDate) return 0;
            else if(modifiedDate < compareWrapper.modifiedDate) return 1;
            return -1;
        }
    }
}