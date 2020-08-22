public class OpportunityTriggerHandlerFuture {
	private static Set<String> ROLE_LIST = new Set<String>{'Primary SE', 'Twilio.org Specialist', 'Partner Specialist', 'PRT Specialist',  'Inside Sales Specialist',  'Secondary SE','Solution Sales Specialist 2', 'Twilio.org Rep', 'Partner Rep'};
	public static List<Id> splitTypeId = /*'1494B0000008OLZQA2'*/new List<Id>{'1494000000000NkAAI', /*'1490U0000008OJhQAM'*/'1491W000000XZB0QAO'};
            
        public static void createPrimaryProduct(String newOppjsonString){
            List<Opportunity> opps = (List<Opportunity>)Json.deserialize(newOppjsonString,List<Opportunity>.class);
            Map<String, Opportunity_Product__c> oppProducts = new Map<String, Opportunity_Product__c>();
            System.debug('oppscreatePrimaryProduct==>'+opps);
            
            
            for(Opportunity opp: opps){
                if(opp.FY_16_Primary_Product__c != null){
                    Opportunity_Product__c prod = new Opportunity_Product__c(Name = opp.FY_16_Primary_Product__c, Primary_Product__c = true, Product_Name__c = opp.FY_16_Primary_Product__c, Launch_Date__c = opp.Launch_Date__c, Amount__c = opp.Amount, Contract_Terms_Months__c = opp.Contract_Terms_Months__c, Opportunity__c = opp.Id);
                    if(opp.FY_16_Primary_Sub_Product__c != null){
                        if(opp.SendGrid_Package_Size__c != null){
                            oppProducts.put(opp.FY_16_Primary_Sub_Product__c + ';' + opp.Id + ';' + opp.SendGrid_Package_Size__c, prod);
                        }
                        else{
                            oppProducts.put(opp.FY_16_Primary_Sub_Product__c + ';' + opp.Id, prod);
                        }
                    }
                    else{
                        oppProducts.put('null' + ';' + opp.Id, prod);
                    }
                }
            }
            if(!oppProducts.isEmpty()) insert oppProducts.values();
            List<Twilio_Sub_Product__c> subProds = new List<Twilio_Sub_Product__c>();
            
            for(String subProdString:  oppProducts.keySet()){
                String productName = subProdString.split(';')[0];
                String size = null;
                if(subProdString.split(';').size() >= 3){size = subProdString.split(';')[2];}
                if(productName != 'null'){
                    Twilio_Sub_Product__c subProd = new Twilio_Sub_Product__c(Name = productName, Primary__c = true, SendGrid_Package_Size__c = size);
                    Opportunity_Product__c prod = oppProducts.get(subProdString);
                    if(prod.Id != null){
                        subProd.Twilio_Product__c = prod.Id;
                        subProds.add(subProd);
                    }
                }
            }
            insert subProds;
        }
    
    public static void keyTwilionChanged(String newOppjsonString, String stroldMap){
        
        List<Opportunity> opps = (List<Opportunity>)Json.deserialize(newOppjsonString,List<Opportunity>.class);
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) JSON.deserialize(stroldMap,  Map<Id, Opportunity>.class);
        List<Opportunity> filteredOpps = new List<Opportunity>();
        
        for(Opportunity opp: opps){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(oldOpp == null){
                if(opp.Technical_Lead__c != null || opp.Twilio_Sales_Engineer_Secondary__c != null
                   || opp.Solution_Sales_Specialist_2__c != null
                   || opp.Twilio_org_Rep__c != null
                   || opp.Alliances_Rep__c != null
                   || opp.Messaging_Specialist__c != null
                   || opp.Inside_Sales_Specialist__c != null){
                       
                       filteredOpps.add(opp);
                   }
            }
            else if(oldOpp.Technical_Lead__c != opp.Technical_Lead__c 
                    || oldOpp.Twilio_Sales_Engineer_Secondary__c != opp.Twilio_Sales_Engineer_Secondary__c 
                    || oldOpp.Solution_Sales_Specialist_2__c != opp.Solution_Sales_Specialist_2__c 
                    || oldOpp.Twilio_org_Rep__c != opp.Twilio_org_Rep__c
                    || oldOpp.Alliances_Rep__c != opp.Alliances_Rep__c
                    || oldOpp.Messaging_Specialist__c != opp.Messaging_Specialist__c
                    || oldOpp.Inside_Sales_Specialist__c != opp.Inside_Sales_Specialist__c){
                        
                        filteredOpps.add(opp);
                    }
        }
        
        if(filteredOpps.isEmpty()) return;
        
        List<OpportunityTeamMember> existingTeamMembers = [SELECT Id, UserId, OpportunityId
                                                           FROM OpportunityTeamMember 
                                                           WHERE OpportunityId =: filteredOpps 
                                                           AND TeamMemberRole IN :ROLE_LIST];
        delete existingTeamMembers;
        
        List<OpportunityTeamMember> insertMembers = new List<OpportunityTeamMember>();
        
        for(Opportunity opp: filteredOpps){
            if(opp.OwnerId != opp.Technical_Lead__c && opp.Technical_Lead__c != null){
                insertMembers.add(createTeamMember(opp.Id, opp.Technical_Lead__c, 'Edit', 'Primary SE'));
            } 
            if(opp.OwnerId != opp.Twilio_Sales_Engineer_Secondary__c && opp.Twilio_Sales_Engineer_Secondary__c != null){
                insertMembers.add(createTeamMember(opp.Id, opp.Twilio_Sales_Engineer_Secondary__c, 'Edit', 'Secondary SE'));
            } 
            if(opp.OwnerId != opp.Solution_Sales_Specialist_2__c && opp.Solution_Sales_Specialist_2__c != null){
                insertMembers.add(createTeamMember(opp.Id, opp.Solution_Sales_Specialist_2__c, 'Edit', 'Solution Sales Specialist 2'));
            } 
            if(opp.OwnerId != opp.Twilio_org_Rep__c && opp.Twilio_org_Rep__c != null){
                insertMembers.add(createTeamMember(opp.Id, opp.Twilio_org_Rep__c, 'Edit', 'Twilio.org Specialist'));
            }
            if(opp.OwnerId != opp.Alliances_Rep__c && opp.Alliances_Rep__c != null){
                insertMembers.add(createTeamMember(opp.Id, opp.Alliances_Rep__c, 'Edit', 'Partner Specialist'));
            }
            if(opp.OwnerId != opp.Messaging_Specialist__c && opp.Messaging_Specialist__c != null){insertMembers.add(createTeamMember(opp.Id, opp.Messaging_Specialist__c, 'Edit', 'PRT Specialist'));}
            if(opp.OwnerId != opp.Inside_Sales_Specialist__c && opp.Inside_Sales_Specialist__c != null){insertMembers.add(createTeamMember(opp.Id, opp.Inside_Sales_Specialist__c, 'Edit', 'Inside Sales Specialist'));}
        }
        
        insert insertMembers;
        
        
        List<OpportunityShare> shares = [SELECT OpportunityAccessLevel FROM OpportunityShare WHERE RowCause = 'Team' AND OpportunityId =: filteredOpps AND OpportunityAccessLevel = 'Read'];
        for(OpportunityShare share: shares){
            share.OpportunityAccessLevel = 'Edit';
        }
        
        update shares;
    }
    
    static OpportunityTeamMember createTeamMember(Id oppId, Id userId, String accessLevel, String role){
        return new OpportunityTeamMember(OpportunityId = oppId, UserId = userId, OpportunityAccessLevel = accessLevel, TeamMemberRole = role);
    }
    
    public static void CSMChanged(String newOppjsonString, String stroldMap){
        
        List<Opportunity> opps = (List<Opportunity>)Json.deserialize(newOppjsonString,List<Opportunity>.class);
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) JSON.deserialize(stroldMap,  Map<Id, Opportunity>.class);
        
        List<Opportunity> filteredOpps = new List<Opportunity>();
        
        for(Opportunity opp: opps){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(oldOpp == null){
                if(opp.CSM_Engaged__c != null){
                    filteredOpps.add(opp);
                }
            }
            else if(oldOpp.CSM_Engaged__c != opp.CSM_Engaged__c && opp.CSM_Engaged__c != null){
                filteredOpps.add(opp);
            }
        }
        
        if(filteredOpps.isEmpty()) return;
        
        List<OpportunityTeamMember> existingTeamMembers = [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId =: filteredOpps AND TeamMemberRole = 'CSM'];
        delete existingTeamMembers;
        
        List<OpportunityTeamMember> insertMembers = new List<OpportunityTeamMember>();
        
        for(Opportunity opp: filteredOpps){
            if(opp.OwnerId != opp.Technical_Lead__c){
                insertMembers.add(new OpportunityTeamMember(OpportunityId = opp.Id, UserId = opp.CSM_Engaged__c, OpportunityAccessLevel = 'Edit', TeamMemberRole = 'CSM'));
            }
        }
        
        insert insertMembers;
        
        List<OpportunityShare> shares = [SELECT OpportunityAccessLevel FROM OpportunityShare WHERE RowCause = 'Team' AND OpportunityId =: filteredOpps AND OpportunityAccessLevel = 'Read'];
        for(OpportunityShare share: shares){
            share.OpportunityAccessLevel = 'Edit';
        }
        
        update shares;
    }
    
    public static void BDRChanged(String NewOppjsonString, String stroldMap){
        
        List<Opportunity> opps = (List<Opportunity>)Json.deserialize(newOppjsonString,List<Opportunity>.class);
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) JSON.deserialize(stroldMap,  Map<Id, Opportunity>.class);
        
        List<Opportunity> filteredOpps = new List<Opportunity>();
        
        for(Opportunity opp: opps){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(oldOpp == null){
                if(opp.BDR_Engaged__c != null){
                    filteredOpps.add(opp);
                }
            }
            else if(oldOpp.BDR_Engaged__c != opp.BDR_Engaged__c && opp.BDR_Engaged__c != null){
                filteredOpps.add(opp);
            }
        }
        
        if(filteredOpps.isEmpty()) return;
        
        List<OpportunityTeamMember> existingTeamMembers = [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId =: filteredOpps AND TeamMemberRole = 'BDR'];
        delete existingTeamMembers;
        
        List<OpportunityTeamMember> insertMembers = new List<OpportunityTeamMember>();
        
        for(Opportunity opp: filteredOpps){
            if(opp.OwnerId != opp.Technical_Lead__c && opp.OwnerId != opp.CSM_Engaged__c){
                insertMembers.add(new OpportunityTeamMember(OpportunityId = opp.Id, UserId = opp.BDR_Engaged__c, OpportunityAccessLevel = 'Edit', TeamMemberRole = 'BDR'));
            }
        }
        
        insert insertMembers;
        
        
        List<OpportunityShare> shares = [SELECT OpportunityAccessLevel FROM OpportunityShare WHERE RowCause = 'Team' AND OpportunityId =: filteredOpps AND OpportunityAccessLevel = 'Read'];
        for(OpportunityShare share: shares){
            share.OpportunityAccessLevel = 'Edit';
        }
        
        update shares;
    }
    
    public static void createOpportunitySplit(String newOppjsonString, String stroldMap){
        
        List<Opportunity> records = (List<Opportunity>)Json.deserialize(newOppjsonString,List<Opportunity>.class);
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) JSON.deserialize(stroldMap,  Map<Id, Opportunity>.class);
        
        List<Opportunity> filtertedRecords = new List<Opportunity>();
        
        for(Opportunity opp: records){
            Opportunity oldRec = oldMap.get(opp.Id);
            if( (oldRec == null && (opp.Solution_Sales_Specialist__c != null || opp.SendGrid_Specialist__c != null) || (oldRec != null && oldRec.Solution_Sales_Specialist__c != opp.Solution_Sales_Specialist__c) || (oldRec != null && oldRec.OwnerId != opp.OwnerId) || (oldRec != null && oldRec.SendGrid_Specialist__c != opp.SendGrid_Specialist__c))){
                filtertedRecords.add(opp);
            }
        }
        
        if(filtertedRecords.isEmpty()) return;
        
        Map<Id, OpportunityTeamMember> oppMembersMap = new Map<Id, OpportunityTeamMember>();
        List<OpportunityTeamMember> existingTeamMembers = [SELECT UserId, OpportunityId FROM OpportunityTeamMember WHERE OpportunityId =: filtertedRecords AND (TeamMemberRole = 'Solution Sales Specialist' OR TeamMemberRole = 'SendGrid Specialist')];
        Set<Id> solutionSpecialistId = new Set<Id>();
        Map<Id, List<OpportunitySplit>> oppSplitMap = new Map<Id, List<OpportunitySplit>>();
        
        for(OpportunityTeamMember member: existingTeamMembers){
            oppMembersMap.put(member.OpportunityId, member);
            solutionSpecialistId.add(member.UserId);
        }
        
        List<OpportunitySplit> existingSplits = [SELECT SplitOwnerId, Opportunity.OwnerId, OpportunityId FROM OpportunitySplit WHERE OpportunityId =: filtertedRecords AND SplitOwnerId =: solutionSpecialistId /*AND SplitTypeId =: splitTypeId[1]*/];
        for(OpportunitySplit split: existingSplits){
            List<OpportunitySplit> splits = oppSplitMap.get(split.OpportunityId);
            if(splits == null || splits.isEmpty()){
                splits = new List<OpportunitySplit>();
            }
            if(split.SplitOwnerId != split.Opportunity.OwnerId){
                splits.add(split);
                oppSplitMap.put(split.OpportunityId, splits);
            }
        }
        
        List<OpportunityTeamMember> insertMembers = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> deleteMembers = new List<OpportunityTeamMember>();
        List<OpportunitySplit> insertSplits = new List<OpportunitySplit>();
        List<OpportunitySplit> deleteSplits = new List<OpportunitySplit>();
        for(Opportunity opp: filtertedRecords){
            OpportunityTeamMember member = oppMembersMap.get(opp.Id);
            if(member != null && member.UserId != opp.Solution_Sales_Specialist__c && member.UserId != opp.SendGrid_Specialist__c){
                if(member.UserId != opp.OwnerId){
                    deleteMembers.add(member);
                }
                else{
                    member.TeamMemberRole = 'Opportunity Owner';
                    insertMembers.add(member);
                }
                if(oppSplitMap.get(opp.Id) != null){
                    deleteSplits.addAll(oppSplitMap.get(opp.Id));
                }
            }
            if(opp.Solution_Sales_Specialist__c != null && (member == null || member.UserId != opp.Solution_Sales_Specialist__c)){
                insertMembers.add(new OpportunityTeamMember(OpportunityId = opp.Id, UserId = opp.Solution_Sales_Specialist__c, OpportunityAccessLevel = 'Edit', TeamMemberRole = 'Solution Sales Specialist'));
            }
            if(opp.SendGrid_Specialist__c != null && (member == null || member.UserId != opp.SendGrid_Specialist__c)){
                insertMembers.add(new OpportunityTeamMember(OpportunityId = opp.Id, UserId = opp.SendGrid_Specialist__c, OpportunityAccessLevel = 'Edit', TeamMemberRole = 'SendGrid Specialist'));
                insertSplits.add(new OpportunitySplit(OpportunityId = opp.Id, SplitOwnerId = opp.SendGrid_Specialist__c, SplitTypeId = splitTypeId[1], SplitPercentage = 100));
            }
        }
        
        delete deleteSplits;
        delete deleteMembers;
        upsert insertMembers;
        insert insertSplits;
        
        List<OpportunityShare> shares = [SELECT OpportunityAccessLevel FROM OpportunityShare WHERE RowCause = 'Team' AND OpportunityId =: filtertedRecords AND OpportunityAccessLevel = 'Read'];
        for(OpportunityShare share: shares){
            share.OpportunityAccessLevel = 'Edit';
        }
        
        update shares;
    }
    
    @future
    public static void createSendGridSplit(String newOppjsonString, String stroldMap){
        
        List<Opportunity> opps = (List<Opportunity>)Json.deserialize(newOppjsonString,List<Opportunity>.class);
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) JSON.deserialize(stroldMap,  Map<Id, Opportunity>.class);
        
        System.debug('ccreateSendGridSplitoldMap==>'+oldMap);
        System.debug('createSendGridSplitrecords==>'+opps);
        
        List<Opportunity> filteredOpps = new List<Opportunity>();
        
        for(Opportunity opp: opps){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if((oldOpp == null && opp.OwnerId != null) || (oldOpp != null && oldOpp.OwnerId != opp.OwnerId)){
                filteredOpps.add(opp);
            } 
        }
        
        if(filteredOpps.isEmpty()) return;
        Id OppId;
        List<OpportunitySplit> splits = new List<OpportunitySplit>();
        for(Opportunity opp: filteredOpps){
            OppId = opp.Id;
            System.debug('OppId==>'+OppId);
            splits.add(new OpportunitySplit(OpportunityId = opp.Id, SplitOwnerId = opp.OwnerId, SplitTypeId = splitTypeId[1], SplitPercentage = 100));
        }
        
        List<Opportunity> theOpp1 = [SELECT Id From Opportunity Where Id =:OppId];
        System.debug('theOpp1==>'+theOpp1);
        System.debug('splits==>'+splits);
        insert splits;
    }
    
    public static void updatePassToPartnerStatus(String newOppjsonString, String stroldMap) {
        
        List<Opportunity> newList = (List<Opportunity>)Json.deserialize(newOppjsonString,List<Opportunity>.class);
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) JSON.deserialize(stroldMap,  Map<Id, Opportunity>.class);
        
        Set<String> finalPartnerStatuses = new Set<String> { 'Closed - Won', 'Closed - Lost', 'Declined' };
            
            // Create a set of opportunities where the  for the opportunities
            Map<Id,Opportunity> allOpportunities = new Map<Id,Opportunity>(); 
        for (Opportunity o : newList) {
            if (o.Twilio_Rep_Status__c == 'Declined' || o.Twilio_Rep_Status__c == 'Approved') {
                if (o.Twilio_Rep_Status__c != oldMap.get(o.Id).Twilio_Rep_Status__c) {
                    allOpportunities.put(o.Id, o);
                }
            }
        }       
        
        if (!allOpportunities.isEmpty()) {
            List<Pass_to_Partner__c> passToPartnerRecs = new List<Pass_to_Partner__c>();
            for (Pass_to_Partner__c p : [
                SELECT Id, Name, Partner_Status__c, Opportunity__c, Opportunity__r.Twilio_Rep_Status__c
                FROM Pass_to_Partner__c
                WHERE Opportunity__c IN :allOpportunities.keySet()
                AND Partner_Status__c NOT IN :finalPartnerStatuses
            ]) {
                if (!finalPartnerStatuses.contains(p.Partner_Status__c)) {
                    if (p.Opportunity__r.Twilio_Rep_Status__c == 'Declined') {
                        p.Partner_Status__c = 'Declined';
                    } else if (p.Opportunity__r.Twilio_Rep_Status__c == 'Approved') {
                        p.Partner_Status__c = 'Accepted';
                    }
                }
                passToPartnerRecs.add(p);
            }
            update passToPartnerRecs;
        }       
    }
    
    public static void updateQuoteConfigEmailSpecialist(String newOppMap, String strOldMap) {
        
        List<Opportunity> newOpptyList = (List<Opportunity>)Json.deserialize(newOppMap,List<Opportunity>.class);
        Map<Id, Opportunity> oldOpptyMap = (Map<Id, Opportunity>) JSON.deserialize(strOldMap,  Map<Id, Opportunity>.class);    
        
        List<Opportunity> opptyLst = filterOpptyHelper(oldOpptyMap, newOpptyList);
        
        if(opptyLst.isEmpty()) return;
        List<Apttus_Proposal__Proposal__c> quoteLst = [ SELECT ID,Email_Specialist__c,Apttus_Proposal__Opportunity__r.SendGrid_Specialist__c
                                                       FROM Apttus_Proposal__Proposal__c
                                                       WHERE Apttus_Proposal__Opportunity__c IN: opptyLst
                                                       AND Apttus_Proposal__Opportunity__r.isclosed = FALSE
                                                       AND Apttus_Proposal__Opportunity__c != NULL
                                                       AND Apttus_Proposal__Opportunity__r.RecordType.DeveloperName = 'Outbound_Opportunity'];
        
        if(quoteLst.isEmpty()) return;                                             
        for(Apttus_Proposal__Proposal__c quoteRec: quoteLst) {
            quoteRec.Email_Specialist__c = quoteRec.Apttus_Proposal__Opportunity__r.SendGrid_Specialist__c;
        } 
        
        List<Apttus_Config2__ProductConfiguration__c> configLst = [ SELECT ID, Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.SendGrid_Specialist__c
                                                                   FROM Apttus_Config2__ProductConfiguration__c
                                                                   WHERE Apttus_QPConfig__Proposald__c IN: quoteLst
                                                                   AND Apttus_QPConfig__Proposald__c != NULL
                                                                   AND Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c != NULL
                                                                   AND Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.RecordType.DeveloperName = 'Outbound_Opportunity'
                                                                   AND Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__c IN: opptyLst
                                                                   AND Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.isclosed = FALSE
                                                                  ];
        
        
        if(configLst.isEmpty()) return;                                                                
        for(Apttus_Config2__ProductConfiguration__c config: configLst) {
            config.Related_Quote_Email_Specialist__c = config.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.SendGrid_Specialist__c;
        }
        update configLst;
        update quoteLst;
    }
    
    public static List<Opportunity> filterOpptyHelper(Map<ID, Opportunity> oldOpptyMap, List<Opportunity> newOppties) {
        List<Opportunity> opptyRet = new List<Opportunity>();
        
        for(Opportunity opp: newOppties){
            Opportunity oldOpp = oldOpptyMap.get(opp.Id);
            if(oldOpp != null && opp.SendGrid_Specialist__c != oldOpp.SendGrid_Specialist__c){
                opptyRet.add(opp);
            }
        }
        return opptyRet;
    }
    
    public static void clearOpportunityOnShortCode(Boolean isUpdate, Boolean isDelete, String newOppMap, String strOldMap) {
        
        List<Opportunity> newList = (List<Opportunity>)Json.deserialize(newOppMap,List<Opportunity>.class);
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) JSON.deserialize(strOldMap,  Map<Id, Opportunity>.class);
        // Create a set of all Short_Code__c records that need to be cleared
        // when the Opportunity.Short_Code__c no longer points to it
        Set<Id> shortCodesToClear = new Set<Id>();
        if (isUpdate) {
            for (Opportunity n : newList) {
                Opportunity o = oldMap.get(n.Id);
                if (n.Short_Code__c == null && o.Short_Code__c != null) {
                    shortCodesToClear.add(o.Short_Code__c);
                }
            }       
        } else if (isDelete) {
            for (Opportunity o : oldMap.values()) {
                if (o.Short_Code__c != null) {
                    shortCodesToClear.add(o.Short_Code__c);
                }
            }
        }
        
        if (!shortCodesToClear.isEmpty()) {
            List<Short_Code__c> shortCodes = [
                SELECT Id, Opportunity__c
                FROM Short_Code__c
                WHERE Id IN :shortCodesToClear
            ];
            if (!shortCodes.isEmpty()) {
                for (Short_Code__c s : shortCodes) {
                    s.Opportunity__c = null;
                }
                
                update shortCodes;
            }
        }
    }
    
    public static void changePrimaryProduct(String newOpp, String strOldMap) {
        
        List<Opportunity> opps = (List<Opportunity>)Json.deserialize(newOpp,List<Opportunity>.class);
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) JSON.deserialize(strOldMap,  Map<Id, Opportunity>.class);
        
        List<Opportunity> filteredOpps = new List<Opportunity>();
        for(Opportunity opp: opps){
            Opportunity oldOpp = oldMap.get(opp.Id);
            if(oldOpp.FY_16_Primary_Product__c != opp.FY_16_Primary_Product__c && opp.FY_16_Primary_Product__c != null){
                filteredOpps.add(opp);
            }
        }
        if(filteredOpps.isEmpty()) return;
        
        List<Opportunity> oppWithProd = [SELECT Id, FY_16_Primary_Product__c, Launch_Date__c ,Amount, Contract_Terms_Months__c,
                                         FY_16_Primary_Sub_Product__c,SendGrid_Package_Size__c,
                                         (SELECT Id, name, Primary_Product__c from Opportunity_Products__r) 
                                         FROM Opportunity
                                         WHERE Id IN:filteredOpps];
        List<Opportunity> insertOpps = new List<Opportunity>();
        List<Opportunity_Product__c> oppProducts = new List<Opportunity_Product__c>();
        
        for(Opportunity opp : oppWithProd) {
            Map<String, Opportunity_Product__c> existProdList = new Map<String, Opportunity_Product__c>();
            Opportunity_Product__c gotcha = NULL; 
            for(Opportunity_Product__c prod: opp.Opportunity_Products__r) {
                if (prod.Primary_Product__c == true) {
                    gotcha = prod;
                } else {
                    existProdList.put(prod.name, prod);
                }
            }
            
            if (gotcha != NULL) {
                //if there already is a product with same name
                if (!existProdList.keyset().contains(opp.FY_16_Primary_Product__c)) {
                    gotcha.Name = opp.FY_16_Primary_Product__c;
                    gotcha.Product_Name__c = opp.FY_16_Primary_Product__c;
                    oppProducts.add(gotcha);
                } else {
                    gotcha.Primary_Product__c = false;
                    existProdList.get(opp.FY_16_Primary_Product__c).Primary_Product__c = true;
                    oppProducts.add(gotcha);
                    oppProducts.add(existProdList.get(opp.FY_16_Primary_Product__c));
                }
            } else { //there is no primary product in current related list
                insertOpps.add(opp);
            }
        }
        if(!insertOpps.isEmpty() ) createPrimaryProduct(JSON.serialize(insertOpps));
        
        update oppProducts;
    }    
    
    public static void updateProductSchedule(String newOpp, String strOldMap){
        
        List<Opportunity> opps = (List<Opportunity>)Json.deserialize(newOpp,List<Opportunity>.class);
        
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
        for(Opportunity theOpp : opps) {
            newMap.Put(theOpp.Id, theOpp);
        }
        Map<Id, Opportunity> oldMap = (Map<Id, Opportunity>) JSON.deserialize(strOldMap,  Map<Id, Opportunity>.class);
        
        List<Product_Schedule__c> psList = new List<Product_Schedule__c>();
        List<Product_Schedule__c> psForUpdate = new List<Product_Schedule__c>();
        Set<Id> oppIDsForReview = new Set<Id>();
        
        for(Id oppId : newMap.keySet()){
            if(oldMap.get(oppId).StageName != 'Closed Won' && newMap.get(oppId).StageName == 'Closed Won'){
                oppIDsForReview.add(oppId);
            }
        }
        
        if(!oppIdsForReview.isEmpty()){
            psList = [SELECT Id, Forecasted_Amount_at_Close__c, Forecast_Amount__c 
                      FROM Product_Schedule__c 
                      WHERE Forecast_Schedule__r.Opportunity__c IN :oppIDsForReview];
        }
        
        if(psList.isEmpty() == TRUE){
            return;
        } else {
            for(Product_Schedule__c p : psList){
                p.Forecasted_Amount_at_Close__c = p.Forecasted_Amount_at_Close__c  == null ? p.Forecast_Amount__c : p.Forecasted_Amount_at_Close__c;
                psForUpdate.add(p);
            }
        }
        
        if(!psList.isEmpty()){
            update psForUpdate;
        }
    }
    
    @future
    public static void opportunityAfterUpdateLTHUCC(String newOpp, String strOldMap){
        
        //OpportunityTriggerHandler.updatePassToPartnerStatus(Trigger.new, Trigger.oldMap);
        updatePassToPartnerStatus(newOpp, strOldMap);
        //OpportunityTriggerHandler.salesEngineerChanged(trigger.new, trigger.oldMap);
        
        //OpportunityTriggerHandler.CSMChanged(trigger.new, trigger.oldMap);
        //OpportunityTriggerHandler.BDRChanged(trigger.new, trigger.oldMap);
        //OpportunityTriggerHandler.keyTwilionChanged(trigger.new, trigger.oldMap);
        system.debug('Limits.getCPUTime2=>'+Limits.getCpuTime());
        keyTwilionChanged(newOpp, strOldMap);
        system.debug('Limits.getCPUTime3=>'+Limits.getCpuTime());
        CSMChanged(newOpp, strOldMap);
        system.debug('Limits.getCPUTime4=>'+Limits.getCpuTime());
        BDRChanged(newOpp, strOldMap);
        
        //OpportunityTriggerHandler.createSendGridSplit(trigger.new, trigger.oldMap);
        
        //FieldSalesForecast.updateSalesForecastsContractValues( Trigger.new, Trigger.oldMap );
        //ForecastSchedule.stampOppsForeSchedsAmount( Trigger.new, Trigger.oldMap );
        
        //for Queueable
        //ForecastSchedule.stampOppsForeSchedsAmount(newOpp, strOldMap);
        
        system.debug('Limits.getCPUTime6=>'+Limits.getCpuTime());
        //ForecastSchedule.shiftOrCreateScheds( Trigger.new, Trigger.oldMap );
        
        //For Queueable
        // ForecastSchedule.shiftOrCreateScheds(newOpp, strOldMap);
        
        system.debug('Limits.getCPUTime7=>'+Limits.getCpuTime());
        //MRRCalculationServices.afterUpdateOpportunity(trigger.new, trigger.oldMap);
        
    }
    
    @future
    public static void opportunityAfterUpdateLT(String newOpp, String strOldMap){
        updateQuoteConfigEmailSpecialist(newOpp, strOldMap);
        system.debug('Limits.getCPUTime8=>'+Limits.getCpuTime());
        
        clearOpportunityOnShortCode(True,False,newOpp,strOldMap);
        
        changePrimaryProduct(newOpp, strOldMap);
        
        
        createOpportunitySplit(newOpp, strOldMap);
        system.debug('Limits.getCPUTime11=>'+Limits.getCpuTime());
        
        updateProductSchedule(newOpp, strOldMap);
        system.debug('Limits.getCPUTime12=>'+Limits.getCpuTime());
    }
    
    @future
    public static void opportunityisInsertLT(String newOpp){
        
        createPrimaryProduct(newOpp);
        
        keyTwilionChanged(newOpp, JSON.serialize(new Map<Id, Opportunity>()) );
        
        CSMChanged(newOpp, JSON.serialize(new Map<Id, Opportunity>()));
        
        BDRChanged(newOpp, JSON.serialize(new Map<Id, Opportunity>()));
        
        createOpportunitySplit(newOpp, JSON.serialize(new Map<Id, Opportunity>()));
        //For Queueable
        //OpportunitySKUHandler.createSKUs(newOpp);
        
        //For Queueable
        //ForecastSchedule.createForecasts(newOpp);
        
        //For Queueable
        // ForecastSchedule.stampOppsForeSchedsAmount(newOpp);
       
        Map<Id, Opportunity> oldMapValue = new Map<Id, Opportunity>();
        //For Queueable
        // FieldSalesForecast.updateSalesForecastsContractValues(newOpp,json.serialize(oldMapValue));
    }
    
    @future
    public static void opportunityisDelete(Boolean isUpdate, Boolean isDelete, String newOppMap, String strOldMap) {
        clearOpportunityOnShortCode(isUpdate,isDelete,newOppMap,strOldMap);
    }
    
    
    
}