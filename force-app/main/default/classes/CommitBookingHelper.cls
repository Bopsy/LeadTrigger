/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name  CommitBookingHelper
*
* @description  Helper class for Commit Booking functionality.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jason Yu	<jayu@twilio.com>
* @modifiedBy     Jason Yu   <jayu@twilio.com>
* @version        1.0
* @created        2019-06-26
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes		  2019-11-21: Jason added method getProductCommitBookings(Id agrRecId, Id productId)
*							  that is called from the CommitBookingHelperGlobal class when a user 
*							  clicks on the "Recalculate Commit Bookings" button.
*
**/
public with sharing class CommitBookingHelper {
    
    public static void getCommitBookings(List<Apttus__APTS_Agreement__c> agrsForCommitBooking){
        List<RecordType> recTypes = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'Commit_Booking__c'];
        Map<String, Id> recTypeMap = new Map<String, Id>();
        for(RecordType recType : recTypes){
            recTypeMap.put(recType.DeveloperName, recType.Id);
        }
        
        List<Commit_Booking__c> commitBookings = new List<Commit_Booking__c>();
        List<Apttus__APTS_Agreement__c> globalAgreementsForReview = new List<Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> productAgreementsForReview = new List<Apttus__APTS_Agreement__c>();
        
        for(Apttus__APTS_Agreement__c agrRec : agrsForCommitBooking){
            if(agrRec.Commit_Type__c == 'Global'){
                globalAgreementsForReview.add(agrRec);
            } else if (agrRec.Commit_Type__c == 'Product'){
                productAgreementsForReview.add(agrRec);
            }
        }
        
        if(!globalAgreementsForReview.isEmpty()){
            Id globalId = recTypeMap.get('Global');
            List<Commit_Booking__c> globalCommitBookings = new List<Commit_Booking__c>();
            createUpdateGlobalCommitBookings(globalAgreementsForReview, globalId);
            commitBookings.addAll(globalCommitBookings);
        }
        
        if(!productAgreementsForReview.isEmpty()){
            Id productId = recTypeMap.get('Product');
            List<Commit_Booking__c> productCommitBookings = new List<Commit_Booking__c>();
            getProductCommitBookings(productAgreementsForReview, productId);
            commitBookings.addAll(productCommitBookings);
        }
        
    }
    
    public static Map<Id,Opportunity> getOppWithOppSKU(Set<Id> oppIds){
        List<AccountSID_to_SKU_Mappings__c> settings = AccountSID_to_SKU_Mappings__c.getAll().values();
        Map<String, AccountSID_to_SKU_Mappings__c> settingMap = new Map<String, AccountSID_to_SKU_Mappings__c>();
        Set<String> oppsidQueryStrings = new Set<String>();
        String queryString = 'Select Id,(SELECT Id,Total_MRR__c';
        for(AccountSID_to_SKU_Mappings__c setting: settings){
            if(setting.Year__c == 2018){
                if(setting.Opp_SKU_Field__c != null && !oppsidQueryStrings.contains(setting.Opp_SKU_Field__c)){
                    oppsidQueryStrings.add(setting.Opp_SKU_Field__c);
                    queryString += ' ,' + setting.Opp_SKU_Field__c ;
                }
                settingMap.put(setting.Product_Name__c, setting);
            }
        }
        queryString += ' FROM Opp_SID_SKUs__r) from opportunity where ID IN:oppIds';
        
        List<Opportunity> sids = database.query(queryString);
        Map<Id,Opportunity> mapOppWithAcntSKU = new Map<Id,Opportunity>(sids);
        
        return mapOppWithAcntSKU;
    }
    
    //JASON ADDED 11-15-19
    public static void getProductCommitBookings(Id agrRecId, Id productId){
        Map<String,Commit_Booking__c> mapProductCommitBookings = new Map<String,Commit_Booking__c>();
        Map<Id,Apttus__APTS_Agreement__c> mapAgreementWithProdCommitSch = new Map<Id,Apttus__APTS_Agreement__c>([Select Id,Apttus__Status__c,Apttus__Contract_End_Date__c ,Related_Opportunity_APTS__c,APTS_Agreement_Effective_Date__c,Standard_Process__c,Commit_Start_Month__c, 
                                                                                                                 Term_Range__c,(Select Id,Commit_Amount__c ,Record_Type_OF_GENERATE__c,Start_Date__c, Product_Group__c  
                                                                                                                                from Commit_Schedules__r where Record_Type_OF_GENERATE__c='Product_Commit' and Product_Group__c!=null
                                                                                                                                order by Start_Date__c) 
                                                                                                                 from Apttus__APTS_Agreement__c where (Commit_Start_Month__c!=null or APTS_Agreement_Effective_Date__c!=null)
                                                                                                                 and Apttus__Status__c='Activated'
                                                                                                                 and (Commit_Frequency__c!='No Commit - PAYG' and Commit_Frequency__c!='No Commit - POC')
                                                                                                                 and Id = :agrRecId]);
        List<Commit_Booking__c> commitBookingRecs = [SELECT Id, 
                                                     		RecordTypeId, 
                                                    		Product_Group__c,
                                                    		Opportunity__c,
                                                     		Agreement__c,
                                                    		Year_1_Committed_Bookings_Comp_Credit__c,
                                                    		Year_2_Committed_Bookings_Comp_Credit__c,
                                                    		Year_3_Committed_Bookings_Comp_Credit__c,
                                                    		Current_MRR__c
                                                     FROM Commit_Booking__c 
                                                     WHERE Agreement__c = :agrRecId];
        List<Id> agreementIds = new List<Id>();
        agreementIds.add(agrRecId);
        
        
        for(Commit_Booking__c commitBookingRec : commitBookingRecs){
            String agreementIdWithProductGroup = commitBookingRec.Agreement__c + commitBookingRec.Product_Group__c;
            commitBookingRec.Year_1_Committed_Bookings_Comp_Credit__c = null;
            commitBookingRec.Year_2_Committed_Bookings_Comp_Credit__c = null;
            commitBookingRec.Year_3_Committed_Bookings_Comp_Credit__c = null;
            mapProductCommitBookings.put(agreementIdWithProductGroup,commitBookingRec);
        }
        
        if(mapAgreementWithProdCommitSch.size()!=0){
            calculateProductCommitBookings(mapAgreementWithProdCommitSch,mapProductCommitBookings);
        }
    }
    
    public static void getProductCommitBookings(List<Apttus__APTS_Agreement__c> productAgreementsForReview, Id productId){
        Map<String,Commit_Booking__c> mapProductCommitBookings = new Map<String,Commit_Booking__c>();
        Map<Id,Apttus__APTS_Agreement__c> mapAgreementWithProdCommitSch = new Map<Id,Apttus__APTS_Agreement__c>([Select Id,Apttus__Status__c,Apttus__Contract_End_Date__c ,Related_Opportunity_APTS__c,APTS_Agreement_Effective_Date__c,Standard_Process__c,Commit_Start_Month__c, 
                                                                                                                 Term_Range__c,(Select Id,Commit_Amount__c ,Record_Type_OF_GENERATE__c,Start_Date__c, Product_Group__c  
                                                                                                                                from Commit_Schedules__r where Record_Type_OF_GENERATE__c='Product_Commit' and Product_Group__c!=null
                                                                                                                                order by Start_Date__c) 
                                                                                                                 from Apttus__APTS_Agreement__c where (Commit_Start_Month__c!=null or APTS_Agreement_Effective_Date__c!=null)
                                                                                                                 and Apttus__Status__c='Activated'
                                                                                                                 and (Commit_Frequency__c!='No Commit - PAYG' and Commit_Frequency__c!='No Commit - POC')
                                                                                                                 and Id IN: productAgreementsForReview]);
        List<Id> agreementIds = new List<Id>();
        Map<Id, Apttus__APTS_Agreement__c> agreementMap = new Map<Id, Apttus__APTS_Agreement__c>(productAgreementsForReview);
        
        for(Apttus__APTS_Agreement__c agrRec : productAgreementsForReview){
            agreementIds.add(agrRec.Id);
        }
        
        List<Commit_Schedule__c> commitScheds = new List<Commit_Schedule__c>();
        Map<Id, Set<String>> agreementToProductGroup = new Map<Id, Set<String>>();
        commitScheds = [SELECT Id, Agreement__c, Product_Group__c FROM Commit_Schedule__c WHERE Agreement__c IN :agreementIds];
        for(Commit_Schedule__c csRec : commitScheds){
            Set<String> prodGroup = new Set<String>();
            if(agreementToProductGroup.get(csRec.Agreement__c) != null){  //maybe error here?
                prodGroup = agreementToProductGroup.get(csRec.Agreement__c);
            }
            prodGroup.add(csRec.Product_Group__c);
            agreementToProductGroup.put(csRec.Agreement__c, prodGroup);
        }
        
        for(Id agreementId : agreementIds){
            Set<String> productGroup = new Set<String>();
            if(agreementToProductGroup.get(agreementId) != null){
                productGroup = agreementToProductGroup.get(agreementId);
                
                for(String prodGroupValue : productGroup){
                    Commit_Booking__c cbRec = new Commit_Booking__c(RecordTypeId = productId,
                                                                    Agreement__c = agreementId,
                                                                    Product_Group__c = prodGroupValue,
                                                                    Opportunity__c = agreementMap.get(agreementId).Related_Opportunity_APTS__c,
                                                                    Year_1_Committed_Bookings_Comp_Credit__c=null,
                                                                    Year_2_Committed_Bookings_Comp_Credit__c=null,
                                                                    Year_3_Committed_Bookings_Comp_Credit__c=null,
                                                                    Current_MRR__c=null);
                    mapProductCommitBookings.put(agreementId + prodGroupValue,cbRec);
                }
            }
        }
        if(mapAgreementWithProdCommitSch.size()!=0){
            calculateProductCommitBookings(mapAgreementWithProdCommitSch,mapProductCommitBookings);
        }
    }
    
    public static void calculateProductCommitBookings(Map<Id,Apttus__APTS_Agreement__c> mapAgreementWithCommitSch, Map<String,Commit_Booking__c> mapProductCommitBookings){
        List<Commit_Booking__c> lstProductCommitBookings = new List<Commit_Booking__c>(); 
        Set<Id> oppIds = new Set<Id>();
        if(mapProductCommitBookings.size()>0){
            for(Apttus__APTS_Agreement__c objAgreement: mapAgreementWithCommitSch.values()){
                if(objAgreement.Commit_Schedules__r.size()>0 && objAgreement.Apttus__Status__c=='Activated'){
                    Date y1StartDate = objAgreement.Commit_Schedules__r[0].Start_Date__c;
                    for(Commit_Schedule__c objCommitSch : objAgreement.Commit_Schedules__r){
                        if(objCommitSch.Commit_Amount__c!=null && objCommitSch.Commit_Amount__c!=0){
                            y1StartDate = objCommitSch.Start_Date__c;
                            break;
                        }
                    }
                    system.debug('+++y1StartDate '+y1StartDate);
                    for(Commit_Schedule__c objCommitSch : objAgreement.Commit_Schedules__r){
                        if(objCommitSch.Commit_Amount__c==null){
                            objCommitSch.Commit_Amount__c=0;
                        }
                        if(mapProductCommitBookings.get(objAgreement.Id+objCommitSch.Product_Group__c).Year_1_Committed_Bookings_Comp_Credit__c==null){
                            mapProductCommitBookings.get(objAgreement.Id+objCommitSch.Product_Group__c).Year_1_Committed_Bookings_Comp_Credit__c=0;
                        }
                        if(mapProductCommitBookings.get(objAgreement.Id+objCommitSch.Product_Group__c).Year_2_Committed_Bookings_Comp_Credit__c==null){
                            mapProductCommitBookings.get(objAgreement.Id+objCommitSch.Product_Group__c).Year_2_Committed_Bookings_Comp_Credit__c=0;
                        }
                        if(mapProductCommitBookings.get(objAgreement.Id+objCommitSch.Product_Group__c).Year_3_Committed_Bookings_Comp_Credit__c==null){
                            mapProductCommitBookings.get(objAgreement.Id+objCommitSch.Product_Group__c).Year_3_Committed_Bookings_Comp_Credit__c=0;
                        }
                        if(objCommitSch.Start_Date__c < y1StartDate.addYears(1)){
                            mapProductCommitBookings.get(objAgreement.Id+objCommitSch.Product_Group__c).Year_1_Committed_Bookings_Comp_Credit__c +=objCommitSch.Commit_Amount__c;
                        }else if(objCommitSch.Start_Date__c >= y1StartDate.addYears(1) && objCommitSch.Start_Date__c < y1StartDate.addYears(2)){
                            mapProductCommitBookings.get(objAgreement.Id+objCommitSch.Product_Group__c).Year_2_Committed_Bookings_Comp_Credit__c +=objCommitSch.Commit_Amount__c;
                        }else if(objCommitSch.Start_Date__c >= y1StartDate.addYears(2) && objCommitSch.Start_Date__c < y1StartDate.addYears(3)){
                            mapProductCommitBookings.get(objAgreement.Id+objCommitSch.Product_Group__c).Year_3_Committed_Bookings_Comp_Credit__c +=objCommitSch.Commit_Amount__c;
                        }
                    }
                }
            }
            lstProductCommitBookings.addall(mapProductCommitBookings.values());
            for(Commit_Booking__c objCom: lstProductCommitBookings){
                oppIds.add(objCom.Opportunity__c);
            }
            List<PMC_to_OppSidSku_MRR_mappings__c> settings = PMC_to_OppSidSku_MRR_mappings__c.getAll().values();
            
            Map<Id,Opportunity> mapOppWithAcntSKU = getOppWithOppSKU(oppIds);
            if(mapOppWithAcntSKU!=null){
                for(Commit_Booking__c objCom: lstProductCommitBookings){
                    Decimal totalMrr = 0;
                    if(objCom!=null && mapOppWithAcntSKU.get(objCom.Opportunity__c).Opp_SID_SKUs__r.size()>0){
                        for(Opp_SID_SKU__c objOppSKU: mapOppWithAcntSKU.get(objCom.Opportunity__c).Opp_SID_SKUs__r){
                            for(PMC_to_OppSidSku_MRR_mappings__c setting: settings){
                                if(setting.Product_Group__c.equalsIgnoreCase(objCom.Product_Group__c)){
                                    system.debug('+++mrr field '+setting.Product_Group__c + objOppSKU.get(setting.Opp_SKU_MRR_Field__c));
                                    totalMrr += (Decimal) objOppSKU.get(setting.Opp_SKU_MRR_Field__c) ;
                                }
                            }
                        }
                    }
                    objCom.Current_MRR__c = totalMrr ;
                }
            }
            upsert lstProductCommitBookings;
            CommitBookingHelper.getCommitSchedulesForUpdate(lstProductCommitBookings);
        }
    }
    
    public static void createUpdateGlobalCommitBookings(List<Apttus__APTS_Agreement__c> globalAgreementsForReview, Id globalId){
        Map<Id,Commit_Booking__c> mapGlobalNonFlexCommitBookings = new Map<Id,Commit_Booking__c>();
        Map<Id,Commit_Booking__c> mapGlobalFlexCommitBookings = new Map<Id,Commit_Booking__c>();
        List<Commit_Booking__c> lstGlobalCommitBookings = new List<Commit_Booking__c>(); 
        Map<String,Commit_Booking__c> mapAgmtIdWithCB = new Map<String,Commit_Booking__c>();
        lstGlobalCommitBookings = [Select Id,Opportunity__c,Agreement__c,Product_Group__c,RecordTypeId,Current_MRR__c,
                                   Year_1_Committed_Bookings_Comp_Credit__c,Year_2_Committed_Bookings_Comp_Credit__c,
                                   Year_3_Committed_Bookings_Comp_Credit__c from Commit_Booking__c Where RecordTypeId=:globalId 
                                   and Agreement__c IN: globalAgreementsForReview];
        Map<Id,Apttus__APTS_Agreement__c> mapAgreementWithCommitSch = new Map<Id,Apttus__APTS_Agreement__c>([Select Id,Apttus__Status__c,Apttus__Contract_End_Date__c ,Related_Opportunity_APTS__c,APTS_Agreement_Effective_Date__c,Standard_Process__c,Commit_Start_Month__c, 
                                                                                                             Term_Range__c,(Select Id,Commit_Amount__c ,Record_Type_OF_GENERATE__c,Start_Date__c 
                                                                                                                            from Commit_Schedules__r where Record_Type_OF_GENERATE__c='Global_Commit' and Product_Group__c=null
                                                                                                                            order by Start_Date__c) 
                                                                                                             from Apttus__APTS_Agreement__c where (Commit_Start_Month__c!=null or APTS_Agreement_Effective_Date__c!=null)
                                                                                                             and Apttus__Status__c='Activated'
                                                                                                             and (Commit_Frequency__c!='No Commit - PAYG' and Commit_Frequency__c!='No Commit - POC')
                                                                                                             and Id IN: globalAgreementsForReview]);
        
        Map<Id,Apttus__APTS_Agreement__c>  mapAgreementWithTier= new Map<Id,Apttus__APTS_Agreement__c>([Select Id,Apttus__Status__c,Apttus__Contract_End_Date__c ,Related_Opportunity_APTS__c,APTS_Agreement_Effective_Date__c,Standard_Process__c,Commit_Start_Month__c, 
                                                                                                        Term_Range__c,(Select Id,Discount_Rate_Start_Date__c,Discount_Rate_End_Date__c,Flex_Tier_Total__c, Flex_Tier_Duration__c, 
                                                                                                                       Flat_Price__c ,Monthly_Units_Purchased__c from Single_BI_Tiers__r where Last_Additional_Schedule__c=false and Product_Group__c='Flex'
                                                                                                                       order by Discount_Rate_Start_Date__c) 
                                                                                                        from Apttus__APTS_Agreement__c where (Commit_Start_Month__c!=null or APTS_Agreement_Effective_Date__c!=null or Apttus__Contract_End_Date__c!=null)
                                                                                                        and Term_Range__c!=null and Apttus__Status__c='Activated'
                                                                                                        and (Commit_Frequency__c!='No Commit - PAYG' and Commit_Frequency__c!='No Commit - POC')
                                                                                                        and Id IN: globalAgreementsForReview]);
        if(lstGlobalCommitBookings.size()!=0){
            for(Commit_Booking__c objGlobal: lstGlobalCommitBookings){
                mapAgmtIdWithCB.put(objGlobal.Agreement__c + objGlobal.Product_Group__c, objGlobal);
                if(objGlobal.Product_Group__c== 'Global - Non-Flex'){
                    mapGlobalNonFlexCommitBookings.put(objGlobal.Agreement__c,objGlobal);
                }else if(objGlobal.Product_Group__c== 'Global - Flex'){
                    mapGlobalFlexCommitBookings.put(objGlobal.Agreement__c,objGlobal);
                }
            }
        }
        if(mapAgmtIdWithCB.size()>0){
            for(Apttus__APTS_Agreement__c objAgreement: globalAgreementsForReview){
                if(!mapAgmtIdWithCB.containsKey(objAgreement.Id + 'Global - Non-Flex')){
                    Commit_Booking__c objNonFlexCB = new Commit_Booking__c(RecordTypeId = globalId,
                                                                           Agreement__c = objAgreement.Id,
                                                                           Opportunity__c = objAgreement.Related_Opportunity_APTS__c,
                                                                           Product_Group__c = 'Global - Non-Flex',
                                                                           Year_1_Committed_Bookings_Comp_Credit__c=null,
                                                                           Year_2_Committed_Bookings_Comp_Credit__c=null,
                                                                           Year_3_Committed_Bookings_Comp_Credit__c=null,
                                                                           Current_MRR__c=null);
                    mapGlobalNonFlexCommitBookings.put(objAgreement.Id,objNonFlexCB);
                }
                if(mapAgreementWithTier!=null && mapAgreementWithTier.get(objAgreement.Id)!=null){
                    if(!mapAgmtIdWithCB.containsKey(objAgreement.Id + 'Global - Flex') && mapAgreementWithTier.get(objAgreement.Id).Single_BI_Tiers__r!=null && mapAgreementWithTier.get(objAgreement.Id).Single_BI_Tiers__r.size()!=0){
                        Commit_Booking__c objFlexCB = new Commit_Booking__c(RecordTypeId = globalId,
                                                                            Agreement__c = objAgreement.Id,
                                                                            Opportunity__c = objAgreement.Related_Opportunity_APTS__c,
                                                                            Product_Group__c = 'Global - Flex',
                                                                            Year_1_Committed_Bookings_Comp_Credit__c=null,
                                                                            Year_2_Committed_Bookings_Comp_Credit__c=null,
                                                                            Year_3_Committed_Bookings_Comp_Credit__c=null,
                                                                            Current_MRR__c=null);
                        mapGlobalFlexCommitBookings.put(objAgreement.Id,objFlexCB);
                    }
                }
            }
        }else{
            for(Apttus__APTS_Agreement__c objAgreement: globalAgreementsForReview){
                Commit_Booking__c objNonFlexCB = new Commit_Booking__c(RecordTypeId = globalId,
                                                                       Agreement__c = objAgreement.Id,
                                                                       Opportunity__c = objAgreement.Related_Opportunity_APTS__c,
                                                                       Product_Group__c = 'Global - Non-Flex',
                                                                       Year_1_Committed_Bookings_Comp_Credit__c=null,
                                                                       Year_2_Committed_Bookings_Comp_Credit__c=null,
                                                                       Year_3_Committed_Bookings_Comp_Credit__c=null,
                                                                       Current_MRR__c=null);
                mapGlobalNonFlexCommitBookings.put(objAgreement.Id,objNonFlexCB);
                if(mapAgreementWithTier!=null && mapAgreementWithTier.get(objAgreement.Id)!=null){
                    if(mapAgreementWithTier.get(objAgreement.Id).Single_BI_Tiers__r!=null && mapAgreementWithTier.get(objAgreement.Id).Single_BI_Tiers__r.size()>0){
                        Commit_Booking__c objFlexCB = new Commit_Booking__c(RecordTypeId = globalId,
                                                                            Agreement__c = objAgreement.Id,
                                                                            Opportunity__c = objAgreement.Related_Opportunity_APTS__c,
                                                                            Product_Group__c = 'Global - Flex',
                                                                            Year_1_Committed_Bookings_Comp_Credit__c=null,
                                                                            Year_2_Committed_Bookings_Comp_Credit__c=null,
                                                                            Year_3_Committed_Bookings_Comp_Credit__c=null,
                                                                            Current_MRR__c=null);
                        mapGlobalFlexCommitBookings.put(objAgreement.Id,objFlexCB);
                    }
                }
            }
        }        
        if(mapGlobalFlexCommitBookings.size()!=0){
            calculateGlobalFlexCommitBookings(mapAgreementWithTier,mapGlobalFlexCommitBookings);
        }
        if(mapGlobalNonFlexCommitBookings.size()!=0){
            calculateGlobalNonFlexCommitBookings(mapAgreementWithCommitSch,mapGlobalNonFlexCommitBookings,mapGlobalFlexCommitBookings);
        }
        
    }
    
    public static void calculateGlobalNonFlexCommitBookings(Map<Id,Apttus__APTS_Agreement__c> mapAgreementWithCommitSch, Map<Id,Commit_Booking__c> mapGlobalNonFlexCommitBookings, Map<Id,Commit_Booking__c> mapGlobalFlexCommitBookings){
        List<Commit_Booking__c> lstGlobalNonFlexCommitBookings = new List<Commit_Booking__c>(); 
        Set<Id> oppIds = new Set<Id>();
        if(mapGlobalNonFlexCommitBookings.size()>0){
            for(Apttus__APTS_Agreement__c objAgreement: mapAgreementWithCommitSch.values()){
                if(objAgreement.Commit_Schedules__r.size()>0 && objAgreement.Apttus__Status__c=='Activated'){
                    Decimal y1=0,y2=0,y3=0;
                    Date y1StartDate = objAgreement.Commit_Schedules__r[0].Start_Date__c;
                    //Added by Amrutha - exclude $0 month forecast
                    for(Commit_Schedule__c objCommitSch : objAgreement.Commit_Schedules__r){
                        if(objCommitSch.Commit_Amount__c!=null && objCommitSch.Commit_Amount__c!=0){
                            y1StartDate = objCommitSch.Start_Date__c;
                            break;
                        }
                    }
                    system.debug('+++y1StartDate22 '+y1StartDate);
                    for(Commit_Schedule__c objCommitSch : objAgreement.Commit_Schedules__r){
                        if(objCommitSch.Commit_Amount__c==null){
                            objCommitSch.Commit_Amount__c=0;
                        }
                        if(objCommitSch.Start_Date__c < y1StartDate.addYears(1)){
                            y1 += objCommitSch.Commit_Amount__c;
                        }else if(objCommitSch.Start_Date__c >= y1StartDate.addYears(1) && objCommitSch.Start_Date__c < y1StartDate.addYears(2)){
                            y2 += objCommitSch.Commit_Amount__c;
                        }else if(objCommitSch.Start_Date__c >= y1StartDate.addYears(2) && objCommitSch.Start_Date__c < y1StartDate.addYears(3)){
                            y3 += objCommitSch.Commit_Amount__c;
                        }
                    }
                    mapGlobalNonFlexCommitBookings.get(objAgreement.Id).Year_1_Committed_Bookings_Comp_Credit__c =y1;
                    mapGlobalNonFlexCommitBookings.get(objAgreement.Id).Year_2_Committed_Bookings_Comp_Credit__c =y2;
                    mapGlobalNonFlexCommitBookings.get(objAgreement.Id).Year_3_Committed_Bookings_Comp_Credit__c =y3;
                    if(mapGlobalFlexCommitBookings.size()>0 && mapGlobalNonFlexCommitBookings.get(objAgreement.Id)!=null && mapGlobalFlexCommitBookings.get(objAgreement.Id)!=null){
                        mapGlobalNonFlexCommitBookings.get(objAgreement.Id).Year_1_Committed_Bookings_Comp_Credit__c = y1 >= mapGlobalFlexCommitBookings.get(objAgreement.Id).Year_1_Committed_Bookings_Comp_Credit__c ? 
                            y1-mapGlobalFlexCommitBookings.get(objAgreement.Id).Year_1_Committed_Bookings_Comp_Credit__c : 0;
                        mapGlobalNonFlexCommitBookings.get(objAgreement.Id).Year_2_Committed_Bookings_Comp_Credit__c = y2 >= mapGlobalFlexCommitBookings.get(objAgreement.Id).Year_2_Committed_Bookings_Comp_Credit__c ? 
                            y2-mapGlobalFlexCommitBookings.get(objAgreement.Id).Year_2_Committed_Bookings_Comp_Credit__c : 0;
                        mapGlobalNonFlexCommitBookings.get(objAgreement.Id).Year_3_Committed_Bookings_Comp_Credit__c = y3 >= mapGlobalFlexCommitBookings.get(objAgreement.Id).Year_3_Committed_Bookings_Comp_Credit__c ? 
                            y3-mapGlobalFlexCommitBookings.get(objAgreement.Id).Year_3_Committed_Bookings_Comp_Credit__c : 0;
                    }
                }
                if(mapGlobalNonFlexCommitBookings.get(objAgreement.Id)!=null)
                lstGlobalNonFlexCommitBookings.add(mapGlobalNonFlexCommitBookings.get(objAgreement.Id));
            }
            for(Commit_Booking__c objCom: mapGlobalNonFlexCommitBookings.values()){
                oppIds.add(objCom.Opportunity__c);
                if(!lstGlobalNonFlexCommitBookings.contains(objCom) && objCom!=null){
                    lstGlobalNonFlexCommitBookings.add(objCom);
                }
            }
            if(lstGlobalNonFlexCommitBookings.size()>0){
                Map<Id,Opportunity> mapOppWithAcntSKU = getOppWithOppSKU(oppIds);
                if(mapOppWithAcntSKU!=null && mapOppWithAcntSKU.size()>0){
                    for(Commit_Booking__c objCom: lstGlobalNonFlexCommitBookings){
                        Decimal totalMrr = 0;
                        if(objCom!=null && objCom.Opportunity__c!=null && mapOppWithAcntSKU.get(objCom.Opportunity__c)!=null && mapOppWithAcntSKU.get(objCom.Opportunity__c).Opp_SID_SKUs__r.size()>0){
                            for(Opp_SID_SKU__c objOppSKU: mapOppWithAcntSKU.get(objCom.Opportunity__c).Opp_SID_SKUs__r){
                                if(objOppSKU.Total_MRR__c!=null && objOppSKU.Flex_MRR__c!=null){
                                	totalMrr += (objOppSKU.Total_MRR__c - objOppSKU.Flex_MRR__c) ;
                                }
                            }
                            objCom.Current_MRR__c = totalMrr ;
                        }
                        
                    }
                }
                upsert lstGlobalNonFlexCommitBookings;
                CommitBookingHelper.getCommitSchedulesForUpdate(lstGlobalNonFlexCommitBookings);
            }
        }
    }
    
    public static void calculateGlobalFlexCommitBookings(Map<Id,Apttus__APTS_Agreement__c> mapAgreementWithTier, Map<Id,Commit_Booking__c> mapGlobalFlexCommitBookings){
        List<Commit_Booking__c> lstGlobalFlexCommitBookings = new List<Commit_Booking__c>(); 
        Set<Id> oppIds = new Set<Id>();
        if(mapGlobalFlexCommitBookings.size()>0){
            for(Apttus__APTS_Agreement__c objAgreement: mapAgreementWithTier.values()){
                if(objAgreement.Single_BI_Tiers__r.size()>0 && objAgreement.APTS_Agreement_Effective_Date__c!=null && 
                   objAgreement.Term_Range__c != null && objAgreement.Apttus__Status__c=='Activated'){
                       Integer monthsPassToSecondYr =0;
                       Integer monthsPassToThirdYr =0;
                       Single_BI_Tier__c singleTierPassedToSecondYr = new Single_BI_Tier__c();
                       Single_BI_Tier__c singleTierPassedToThirdYr = new Single_BI_Tier__c();
                       Date endDateSecondYr = null;
                       Date endDateThirdYr = null;
                       Date startDateSecondYr = null;
                       Date startDateThirdYr = null;
                       Date y1StartDate = objAgreement.Single_BI_Tiers__r[0].Discount_Rate_Start_Date__c;
                       Decimal y1=0,y2=0,y3=0;
                       Date agreementEndDate = objAgreement.Apttus__Contract_End_Date__c!=null ? objAgreement.Apttus__Contract_End_Date__c : 
                       objAgreement.Commit_Start_Month__c==null ? objAgreement.APTS_Agreement_Effective_Date__c.addMonths(Integer.valueof(objAgreement.Term_Range__c)) :
                       objAgreement.Commit_Start_Month__c.addMonths(Integer.valueof(objAgreement.Term_Range__c));
                       
                       for(Single_BI_Tier__c objSingleTier: objAgreement.Single_BI_Tiers__r){
                           Date endDate =objSingleTier.Discount_Rate_End_Date__c;
                           Date agreementDate = objAgreement.Commit_Start_Month__c==null ? 
                               objAgreement.APTS_Agreement_Effective_Date__c : 
                           objAgreement.Commit_Start_Month__c;
                           if(agreementDate!=null){
                               endDate = objSingleTier.Discount_Rate_End_Date__c!=null ? objSingleTier.Discount_Rate_End_Date__c : agreementDate.addMonths(Integer.valueof(objAgreement.Term_Range__c));
                               endDate = endDate <= agreementEndDate ? endDate : agreementEndDate;
                           }
                           if(objSingleTier.Discount_Rate_Start_Date__c <= endDate){
                               if(objSingleTier.Discount_Rate_Start_Date__c < y1StartDate.addYears(1)){
                                   if(endDate < y1StartDate.addYears(1)){
                                       y1 += objSingleTier.Flex_Tier_Total__c;
                                   }else{
                                       Integer monthsConsidered = Math.abs(objSingleTier.Discount_Rate_Start_Date__c.monthsBetween(y1StartDate.addYears(1)))
                                           + Math.abs(((objSingleTier.Discount_Rate_Start_Date__c.day()- y1StartDate.addYears(1).day())/27));
                                       monthsPassToSecondYr = Math.abs(y1StartDate.addYears(1).monthsBetween(endDate))
                                           + Math.abs(((y1StartDate.addYears(1).day()- endDate.day())/27));
                                       singleTierPassedToSecondYr = objSingleTier;
                                       startDateSecondYr = endDate.addMonths(-monthsPassToSecondYr).addDays(1);
                                       endDateSecondYr = endDate;
                                       y1 += objSingleTier.Flat_Price__c * objSingleTier.Monthly_Units_Purchased__c * monthsConsidered;
                                       System.debug('+++monthsConsidered111 '+monthsConsidered);
                                       System.debug('+++monthsPassToSecondYr111 '+monthsPassToSecondYr);
                                   }
                                   
                               }else if(objSingleTier.Discount_Rate_Start_Date__c >= y1StartDate.addYears(1) && objSingleTier.Discount_Rate_Start_Date__c < y1StartDate.addYears(2)){
                                   if(endDate < y1StartDate.addYears(2)){
                                       y2 += objSingleTier.Flex_Tier_Total__c;
                                   }else{
                                       Integer monthsConsidered = Math.abs(objSingleTier.Discount_Rate_Start_Date__c.monthsBetween(y1StartDate.addYears(2)))
                                           + Math.abs(((objSingleTier.Discount_Rate_Start_Date__c.day()- y1StartDate.addYears(2).day())/27));
                                       monthsPassToThirdYr = Math.abs(y1StartDate.addYears(2).monthsBetween(endDate))
                                           + Math.abs(((y1StartDate.addYears(2).day()- endDate.day())/27));
                                       singleTierPassedToThirdYr = objSingleTier;
                                       startDateThirdYr = endDate.addMonths(-monthsPassToThirdYr).addDays(1);
                                       endDateThirdYr = endDate;
                                       y2 += objSingleTier.Flat_Price__c * objSingleTier.Monthly_Units_Purchased__c * monthsConsidered;
                                       System.debug('+++monthsConsidered333 '+monthsConsidered);
                                       System.debug('+++monthsPassToSecondYr333 '+monthsPassToSecondYr);
                                       System.debug('+++singleTierPassedToThirdYr333 '+monthsPassToThirdYr);
                                   }
                                   
                               }else if((objSingleTier.Discount_Rate_Start_Date__c >= y1StartDate.addYears(1) || objSingleTier.Discount_Rate_Start_Date__c >= y1StartDate.addYears(2))
                                        && objSingleTier.Discount_Rate_Start_Date__c < y1StartDate.addYears(3)){
                                            if(endDate < y1StartDate.addYears(3)){
                                                y3 += objSingleTier.Flex_Tier_Total__c;
                                            }else{
                                                Integer monthsConsidered = Math.abs(objSingleTier.Discount_Rate_Start_Date__c.monthsBetween(y1StartDate.addYears(3)))
                                                    + Math.abs(((objSingleTier.Discount_Rate_Start_Date__c.day()- y1StartDate.addYears(3).day())/27));
                                                y3 += objSingleTier.Flat_Price__c * objSingleTier.Monthly_Units_Purchased__c * monthsConsidered;
                                            }
                                            
                                        }
                           }
                       }
                       if(monthsPassToSecondYr > 0){
                           if(endDateSecondYr < y1StartDate.addYears(2)){
                               y2 += singleTierPassedToSecondYr.Flat_Price__c * singleTierPassedToSecondYr.Monthly_Units_Purchased__c * monthsPassToSecondYr;
                               monthsPassToSecondYr=0;
                               singleTierPassedToSecondYr=null;
                           }else{
                               Integer monthsConsidered = Math.abs(startDateSecondYr.monthsBetween(y1StartDate.addYears(2)))
                                   + Math.abs(((startDateSecondYr.day()- y1StartDate.addYears(2).day())/27));
                               monthsPassToSecondYr = Math.abs(y1StartDate.addYears(2).monthsBetween(endDateSecondYr))
                                   + Math.abs(((y1StartDate.addYears(2).day()- endDateSecondYr.day())/27));
                               startDateSecondYr = endDateSecondYr.addMonths(-monthsPassToSecondYr).addDays(1);
                               y2 += singleTierPassedToSecondYr.Flat_Price__c * singleTierPassedToSecondYr.Monthly_Units_Purchased__c * monthsConsidered;
                               System.debug('+++monthsConsidered222 '+monthsConsidered);
                               System.debug('+++monthsPassToSecondYr222 '+monthsPassToSecondYr);
                           }
                       }
                       if(monthsPassToSecondYr > 0){
                           if(endDateSecondYr < y1StartDate.addYears(3)){
                               y3 += singleTierPassedToSecondYr.Flat_Price__c * singleTierPassedToSecondYr.Monthly_Units_Purchased__c * monthsPassToSecondYr;
                               monthsPassToSecondYr=0;
                               singleTierPassedToSecondYr=null;
                           }else{
                               Integer monthsConsidered = Math.abs(startDateSecondYr.monthsBetween(y1StartDate.addYears(3)))
                                   + Math.abs(((startDateSecondYr.day()- y1StartDate.addYears(3).day())/27));
                               monthsPassToSecondYr = Math.abs(y1StartDate.addYears(3).monthsBetween(endDateSecondYr))
                                   + Math.abs(((y1StartDate.addYears(3).day()- endDateSecondYr.day())/27));
                               y3 += singleTierPassedToSecondYr.Flat_Price__c * singleTierPassedToSecondYr.Monthly_Units_Purchased__c * monthsConsidered;
                               System.debug('+++monthsConsidered444 '+monthsConsidered);
                               System.debug('+++monthsPassToSecondYr444 '+monthsPassToSecondYr);
                           }
                       }if(monthsPassToThirdYr > 0){
                           if(endDateThirdYr < y1StartDate.addYears(3)){
                               y3 += singleTierPassedToThirdYr.Flat_Price__c * singleTierPassedToThirdYr.Monthly_Units_Purchased__c * monthsPassToThirdYr;
                               monthsPassToThirdYr=0;
                               singleTierPassedToThirdYr=null;
                           }else{
                               Integer monthsConsidered = Math.abs(startDateThirdYr.monthsBetween(y1StartDate.addYears(3)))
                                   + Math.abs(((startDateThirdYr.day()- y1StartDate.addYears(3).day())/27));
                               y3 += singleTierPassedToThirdYr.Flat_Price__c * singleTierPassedToThirdYr.Monthly_Units_Purchased__c * monthsConsidered;
                               System.debug('+++monthsConsidered555 '+monthsConsidered);
                               System.debug('+++monthsPassToSecondYr555 '+monthsPassToSecondYr);
                           }
                       }
                       mapGlobalFlexCommitBookings.get(objAgreement.Id).Year_1_Committed_Bookings_Comp_Credit__c =y1;
                       mapGlobalFlexCommitBookings.get(objAgreement.Id).Year_2_Committed_Bookings_Comp_Credit__c =y2;
                       mapGlobalFlexCommitBookings.get(objAgreement.Id).Year_3_Committed_Bookings_Comp_Credit__c =y3;
                   }
                if(mapGlobalFlexCommitBookings.get(objAgreement.Id)!=null)
                lstGlobalFlexCommitBookings.add(mapGlobalFlexCommitBookings.get(objAgreement.Id));
            }
            for(Commit_Booking__c objCom: mapGlobalFlexCommitBookings.values()){
                oppIds.add(objCom.Opportunity__c);
                if(!lstGlobalFlexCommitBookings.contains(objCom) && objCom!=null){
                    lstGlobalFlexCommitBookings.add(objCom);
                }
            }
            if(lstGlobalFlexCommitBookings.size()>0){
                Map<Id,Opportunity> mapOppWithAcntSKU = getOppWithOppSKU(oppIds);
                if(mapOppWithAcntSKU!=null && mapOppWithAcntSKU.size()>0){
                    for(Commit_Booking__c objCom: lstGlobalFlexCommitBookings){
                        Decimal flexMrr = 0;
                        if(objCom!=null && objCom.Opportunity__c!=null && mapOppWithAcntSKU.get(objCom.Opportunity__c)!=null && mapOppWithAcntSKU.get(objCom.Opportunity__c).Opp_SID_SKUs__r.size()>0){
                            for(Opp_SID_SKU__c objOppSKU: mapOppWithAcntSKU.get(objCom.Opportunity__c).Opp_SID_SKUs__r){
                                if(objOppSKU.Flex_MRR__c!=null){
                                	flexMrr += objOppSKU.Flex_MRR__c ;
                                }
                            }
                            objCom.Current_MRR__c = flexMrr ;
                        }
                        
                    }
                }
                upsert lstGlobalFlexCommitBookings;
                CommitBookingHelper.getCommitSchedulesForUpdate(lstGlobalFlexCommitBookings);
            }
        }
    }
    
    public static void getCommitSchedulesForUpdate(List<Commit_Booking__c> commitBookings){
        List<Commit_Schedule__c> commitScheds = new List<Commit_Schedule__c>();
        Map<Id, List<Commit_Booking__c>> agreementIdToCommitBookingMap = new Map<Id, List<Commit_Booking__c>>();
        Map<Id, List<Commit_Schedule__c>> agreementIdToCommitScheduleMap = new Map<Id, List<Commit_Schedule__c>>();
        
        //Create a Map for Commit Bookings grouped by Agreement Id as the key.
        for(Commit_Booking__c commitBooking : commitBookings){
            List<Commit_Booking__c> tempCommitBookingList = new List<Commit_Booking__c>();
            if(agreementIdToCommitBookingMap.get(commitBooking.Agreement__c) != null){
                tempCommitBookingList = agreementIdToCommitBookingMap.get(commitBooking.Agreement__c);
            }
            tempCommitBookingList.add(commitBooking);
            agreementIdToCommitBookingMap.put(commitBooking.Agreement__c, tempCommitBookingList);
        }
        
        //Get a list of all the Commit Schedules and group them with the Agreement Id as the key.
        List<Commit_Schedule__c> commitSchedsForReview = new List<Commit_Schedule__c>();
        commitSchedsForReview = [SELECT Id, Agreement__c, Product_Group__c FROM Commit_Schedule__c WHERE Agreement__c IN :agreementIdToCommitBookingMap.keySet()];
        for(Commit_Schedule__c commitSched : commitSchedsForReview){
            List<Commit_Schedule__c> tempCommitSchedList = new List<Commit_Schedule__c>();
            if(agreementIdToCommitScheduleMap.get(commitSched.Agreement__c) != null){
                tempCommitSchedList = agreementIdToCommitScheduleMap.get(commitSched.Agreement__c);
            }
            tempCommitSchedList.add(commitSched);
            agreementIdToCommitScheduleMap.put(commitSched.Agreement__c, tempCommitSchedList);
        }
        
        for(Id agreementId : agreementIdToCommitBookingMap.keySet()){
            List<Commit_Booking__c> tempCommitBookings = new List<Commit_Booking__c>();
            List<Commit_Schedule__c> tempCommitScheds = new List<Commit_Schedule__c>();
            tempCommitBookings = agreementIdToCommitBookingMap.get(agreementId);
            tempCommitScheds = agreementIdToCommitScheduleMap.get(agreementId);
            
            for(Commit_Booking__c commitBooking : tempCommitBookings){
                if(tempCommitScheds!=null){
                    for(Commit_Schedule__c commitSched : tempCommitScheds){
                        
                        if(commitBooking.Product_Group__c == commitSched.Product_Group__c 
                           && commitBooking.Product_Group__c != null && commitSched.Product_Group__c != null){  //This is the check for Product Commit.
                               System.debug('This is Commit Booking Product Group --> ' + commitBooking.Product_Group__c +
                                            '.  This is Commit Sched Product Group --> ' + commitSched.Product_Group__c);
                               commitSched.Commit_Booking__c = commitBooking.Id;
                               commitScheds.add(commitSched);
                           } else if (commitBooking.Product_Group__c == 'Global - Non-Flex' && commitSched.Product_Group__c == null){  //This is the check for Global Commit.
                               commitSched.Commit_Booking__c = commitBooking.Id;
                               commitScheds.add(commitSched);
                           }
                    }
                }
            }
        }
        update commitScheds;
    }
    
}