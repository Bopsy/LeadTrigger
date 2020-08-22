/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name 		  DealWorkstreamTriggerHandler
*
* @description 	  Service class that contains the logic related to workstream object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal	 <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal	 <arenjal@twilio.com>
* @version        1.0
* @created        2019-03-05
* @modified       
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class DealWorkstreamTriggerHandler {
    
    public static void validateType(List<Deal_Workstream__c> lstDealWorkstreams){
        Set<Id> parentIds = new Set<Id>();
        String queryString = 'SELECT Id, type__c';
        String whereCon = ' from Deal_Workstream__c Where';
        
        for(Workstream_Rollup_Mapping__c setting : Workstream_Rollup_Mapping__c.getAll().values()){
            queryString += ' ,' + setting.Parent_Lookup_API_Field__c ;
            whereCon += ' ' + setting.Parent_Lookup_API_Field__c + ' IN:parentIds OR' ;
            for(Deal_Workstream__c objDealWork: lstDealWorkstreams){
                if(objDealWork.get(setting.Parent_Lookup_API_Field__c)!=null){
                    parentIds.add((Id) objDealWork.get(setting.Parent_Lookup_API_Field__c));
                }
            }
        }
        queryString = queryString + whereCon.removeEndIgnoreCase('OR');
        System.debug('++query '+queryString);
        List<Deal_Workstream__c> lstAllDealWorkstreams = database.query(queryString);
        for(Workstream_Rollup_Mapping__c setting : Workstream_Rollup_Mapping__c.getAll().values()){
            for(Deal_Workstream__c objAllDealWork: lstAllDealWorkstreams){
                for(Deal_Workstream__c objDealWork: lstDealWorkstreams){
                    if(objAllDealWork.get(setting.Parent_Lookup_API_Field__c) == objDealWork.get(setting.Parent_Lookup_API_Field__c) && objAllDealWork.type__c == objDealWork.type__c && objDealWork.type__c!='Other'){
                        objDealWork.type__c.addError(System.Label.Deal_workstream_type);
                    }
                }
            }
        }
    }
    
    public static void workstreamTimelineOnInsert(List<Deal_Workstream__c> lstDealWorkstreams){
        List<Deal_Workstream__c> lstWorkstreamsToCalculate = new List<Deal_Workstream__c>();
        List<Deal_Workstream_Timeline__c> lstTimelines = new List<Deal_Workstream_Timeline__c>();
        for(Deal_Workstream__c objDealWork: lstDealWorkstreams){
            if(objDealWork.Status__c!=null){
                Deal_Workstream_Timeline__c objTimeline = new Deal_Workstream_Timeline__c();
                objTimeline.Deal_Workstream__c = objDealWork.Id;
                objTimeline.From_Date__c  = objDealWork.CreatedDate;
                objTimeline.Order__c = 1;
                objTimeline.Workstream_Status__c = objDealWork.Status__c;
                lstTimelines.add(objTimeline);
            }
            if(objDealWork.Status__c=='Complete' && objDealWork.End_Date__c!=null && objDealWork.End_Date__c>=objDealWork.CreatedDate){
                lstWorkstreamsToCalculate.add(objDealWork);
            }
        }
        Database.insert(lstTimelines, false);
        if(lstWorkstreamsToCalculate.size()>0){
            calculateRollupTotalDays(lstWorkstreamsToCalculate);
        }
    }
    
    public static void workstreamTimelineOnUpdate(List<Deal_Workstream__c> lstDealWorkstreams, Map<Id,Deal_Workstream__c> oldMap){
    	List<Deal_Workstream__c> lstNewDealWorks = new List<Deal_Workstream__c>();
        List<Deal_Workstream__c> lstWorkstreamsToCalculate = new List<Deal_Workstream__c>();
        for(Deal_Workstream__c objDealWork: lstDealWorkstreams){
            if((oldMap.get(objDealWork.id).Status__c != objDealWork.Status__c) && objDealWork.Status__c!=null){
                lstNewDealWorks.add(objDealWork);
            }
            if((oldMap.get(objDealWork.id).Total_Time__c != objDealWork.Total_Time__c)){
                    lstWorkstreamsToCalculate.add(objDealWork);
            }
        }
        List<Deal_Workstream_Timeline__c> lstTimelines = new List<Deal_Workstream_Timeline__c>();
        for(Deal_Workstream__c objDealWork: lstNewDealWorks){
            Deal_Workstream_Timeline__c objTimeline = new Deal_Workstream_Timeline__c();
            objTimeline.Deal_Workstream__c = objDealWork.Id;
            objTimeline.Workstream_Status__c = objDealWork.Status__c;
            objTimeline.Reopened__c = (oldMap.get(objDealWork.id).Status__c ==System.Label.Complete_status_value || oldMap.get(objDealWork.id).Status__c ==System.Label.Customer_Review_status_value) ? true : false;
            lstTimelines.add(objTimeline);
        }
        Database.insert(lstTimelines, false);
        List<Deal_Workstream_Timeline__c> lstUpdateTimelines = new List<Deal_Workstream_Timeline__c>();
        Map<Id,Deal_Workstream__c> mapDealWork = new Map<Id,Deal_Workstream__c>([Select Id,Status__c,CreatedDate,(Select Id,Deal_Workstream__c,
                                                                                                                  From_Date__c,Order__c,Reopened__c,To_Date__c,
                                                                                                                  Workstream_Status__c from Deal_Workstream_Timelines__r order by From_Date__c desc limit 2)
                                                                                 from  Deal_Workstream__c where Id IN: lstNewDealWorks]);
        if(mapDealWork.size()>0){
            for(Deal_Workstream__c objDealWork : mapDealWork.values()){
                if(objDealWork.Deal_Workstream_Timelines__r.size()>1){
                    objDealWork.Deal_Workstream_Timelines__r[1].To_Date__c = objDealWork.Deal_Workstream_Timelines__r[0].From_Date__c;
                    objDealWork.Deal_Workstream_Timelines__r[0].Order__c = objDealWork.Deal_Workstream_Timelines__r[1].Order__c +1;
                    lstUpdateTimelines.addAll(objDealWork.Deal_Workstream_Timelines__r);
                }
            }
        }
        Database.update(lstUpdateTimelines, false);
        if(lstWorkstreamsToCalculate.size()>0){
            calculateRollupTotalDays(lstWorkstreamsToCalculate);
        }
    }
    
    public static void workstreamTimelineOnDelete(List<Deal_Workstream__c> lstDealWorkstreams){
        List<Deal_Workstream__c> lstWorkstreamsToCalculate = new List<Deal_Workstream__c>();
        for(Deal_Workstream__c objDealWork: lstDealWorkstreams){
            if(objDealWork.Status__c=='Complete' && objDealWork.End_Date__c!=null && objDealWork.End_Date__c>=objDealWork.CreatedDate){
                lstWorkstreamsToCalculate.add(objDealWork);
            }
        }
        if(lstWorkstreamsToCalculate.size()>0){
            calculateRollupTotalDays(lstWorkstreamsToCalculate);
        }
    }
    
    public static void calculateRollupTotalDays(List<Deal_Workstream__c> lstDealWorkstreams){
        Set<Id> parentIds = new Set<Id>();
        String queryString = 'SELECT Id, Total_Time__c';
        String whereCon = ' from Deal_Workstream__c Where';
        List<Sobject> lstSobj = new List<Sobject>();
        Map<String,List<Deal_Workstream__c>> mapParentIdWithWorkstreams = new Map<String,List<Deal_Workstream__c>>();
        
        //to get parent ids of all workstreams
        for(Workstream_Rollup_Mapping__c setting : Workstream_Rollup_Mapping__c.getAll().values()){
            queryString += ' ,' + setting.Parent_Lookup_API_Field__c ;
            whereCon += ' ' + setting.Parent_Lookup_API_Field__c + ' IN:parentIds OR' ;
            for(Deal_Workstream__c objDealWork: lstDealWorkstreams){
                if(objDealWork.get(setting.Parent_Lookup_API_Field__c)!=null){
                    parentIds.add((Id) objDealWork.get(setting.Parent_Lookup_API_Field__c));
                }
            }
        }
        queryString = queryString + whereCon.removeEndIgnoreCase('OR');
        System.debug('++query '+queryString);
        List<Deal_Workstream__c> lstWorkstreams = database.query(queryString);
        System.debug('++lstWorkstreams '+lstWorkstreams);
        
        //prepare a map where key->parentid-parent API field and values->workstreams related to that parent
        for(Workstream_Rollup_Mapping__c setting : Workstream_Rollup_Mapping__c.getAll().values()){
            for(Deal_Workstream__c objDealWork: lstWorkstreams){
                if(objDealWork.get(setting.Parent_Lookup_API_Field__c)!=null){
                    String leftKey = (Id) objDealWork.get(setting.Parent_Lookup_API_Field__c) + '-' + setting.Parent_Lookup_API_Field__c;
                    if(mapParentIdWithWorkstreams.containsKey(leftKey )) {
                        List<Deal_Workstream__c> lstWorkstream = mapParentIdWithWorkstreams.get(leftKey);
                        lstWorkstream.add(objDealWork);
                        mapParentIdWithWorkstreams.put(leftKey, lstWorkstream);
                    } else {
                        mapParentIdWithWorkstreams.put(leftKey, new List<Deal_Workstream__c> { objDealWork });
                    }
                }
            }
        }
        
        //using custom setting roll up all child duration values to update parent total duration
        if(mapParentIdWithWorkstreams.size()>0){
            for(Workstream_Rollup_Mapping__c setting : Workstream_Rollup_Mapping__c.getAll().values()){
                for(String mapKey : mapParentIdWithWorkstreams.keyset()){
                    if(setting.Parent_Lookup_API_Field__c==mapKey.substringAfter('-')){
                        Sobject obj = Schema.getGlobalDescribe().get(setting.Parent_Object_API_Name__c).newSObject();
                        obj.id= (ID) mapKey.substringBefore('-');
                        Decimal total=0;
                        for(Deal_Workstream__c objDealWork: mapParentIdWithWorkstreams.get(mapKey)){
                            total += (Decimal)objDealWork.get(setting.Child_API_Field__c);
                        }
                        obj.put(setting.Parent_API_Field__c,total);
                        lstSobj.add(obj);
                    }
                }
            }
            database.update(lstSobj,false);
        }
    }
}