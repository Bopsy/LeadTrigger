trigger MQLRoundRobin on FSR__c (before insert, before update) {
    
    if(trigger.isBefore){
        PartnerInquiryRoundRobin.WrapperClassToFilterRecords  inquiryRecordList = new PartnerInquiryRoundRobin.WrapperClassToFilterRecords();
        if(trigger.isInsert){
			inquiryRecordList = PartnerInquiryRoundRobin.filterRecords(trigger.new);
            if(inquiryRecordList.partnerRecordList != null && !inquiryRecordList.partnerRecordList.isEmpty()) PartnerInquiryRoundRobin.beforeInsert(inquiryRecordList.partnerRecordList);
            if(inquiryRecordList.mqlRecordList != null && !inquiryRecordList.mqlRecordList.isEmpty()) MQLRoundRobinServices.beforeInsert(inquiryRecordList.mqlRecordList);
        }
        else if(trigger.isUpdate){
            inquiryRecordList = PartnerInquiryRoundRobin.filterRecords(trigger.new);
            if(inquiryRecordList.partnerRecordList != null && !inquiryRecordList.partnerRecordList.isEmpty()) PartnerInquiryRoundRobin.beforeUpdate(inquiryRecordList.partnerRecordList , trigger.oldMap);
            if(inquiryRecordList.mqlRecordList != null && !inquiryRecordList.mqlRecordList.isEmpty()) MQLRoundRobinServices.beforeUpdate(inquiryRecordList.mqlRecordList, trigger.oldMap);
        }
    }
}