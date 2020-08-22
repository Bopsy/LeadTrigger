/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name           SingleBITierTriggerHandler
*
* @description    Service class that contains the logic related to single BI tier object.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Amrutha Renjal     <arenjal@twilio.com>
* @modifiedBy     Amrutha Renjal     <arenjal@twilio.com>
* @version        1.0
* @created        2018-01-29
* @modified       
* @systemLayer    
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
*
**/
public class SingleBITierTriggerHandler {
    
    //Method to calculate total flex commit
    public static void updateSingleBIDiscount(Set<Id> setSingleDiscountIds){
        List<Single_BI_Discount__c> lstSingleDiscounts = [Select Id,Total_Flex_Commit__c,
                                                          (Select Id,Agreement__c, Flex_Tier_Total__c ,Product_Group__c, Discount_Rate_End_Date__c,Discount_Rate_Start_Date__c,
                                                           Flat_Price__c ,Monthly_Units_Purchased__c,Agreement__r.Commit_Start_Month__c,Agreement__r.APTS_Agreement_Effective_Date__c,
                                                           Agreement__r.Apttus__Contract_End_Date__c,Agreement__r.Term_Range__c,Agreement__r.Apttus__Status__c from Single_BI_Tiers__r where Product_Group__c = 'Flex' and 
                                                           Last_Additional_Schedule__c=false and 
                                                           (Agreement__r.Commit_Frequency__c!='No Commit - PAYG' and Agreement__r.Commit_Frequency__c!='No Commit - POC') and
                                                           (Agreement__r.Commit_Start_Month__c!=null or Agreement__r.APTS_Agreement_Effective_Date__c!=null or Agreement__r.Apttus__Contract_End_Date__c!=null)
                                                           and Agreement__r.Term_Range__c!=null and Agreement__r.Apttus__Status__c='Activated') 
                                                          from Single_BI_Discount__c where Id In: setSingleDiscountIds];
        
        if(lstSingleDiscounts.size()>0){
            for(Single_BI_Discount__c objSingleDiscount: lstSingleDiscounts){
                objSingleDiscount.Total_Flex_Commit__c=0;
                if(objSingleDiscount.Single_BI_Tiers__r.size()>0){
                    for(Single_BI_Tier__c objSingleTier: objSingleDiscount.Single_BI_Tiers__r){
                        if(objSingleTier.Agreement__c!=null){
                            Date agreementEndDate = objSingleTier.Agreement__r.Apttus__Contract_End_Date__c!=null ? objSingleTier.Agreement__r.Apttus__Contract_End_Date__c : 
                            objSingleTier.Agreement__r.Commit_Start_Month__c==null ? objSingleTier.Agreement__r.APTS_Agreement_Effective_Date__c.addMonths(Integer.valueof(objSingleTier.Agreement__r.Term_Range__c)) :
                            objSingleTier.Agreement__r.Commit_Start_Month__c.addMonths(Integer.valueof(objSingleTier.Agreement__r.Term_Range__c));
                            
                            if(objSingleTier.Flex_Tier_Total__c !=null ){
                                if(objSingleTier.Discount_Rate_Start_Date__c <= agreementEndDate && 
                                   (objSingleTier.Discount_Rate_End_Date__c <= agreementEndDate || objSingleTier.Discount_Rate_End_Date__c==null)){
                                       objSingleDiscount.Total_Flex_Commit__c += objSingleTier.Flex_Tier_Total__c;
                                   }else if(objSingleTier.Discount_Rate_Start_Date__c <= agreementEndDate){
                                       Integer monthsConsidered = Math.abs(objSingleTier.Discount_Rate_Start_Date__c.monthsBetween(agreementEndDate))
                                           + Math.abs(((objSingleTier.Discount_Rate_Start_Date__c.day()- agreementEndDate.day())/27));
                                       objSingleDiscount.Total_Flex_Commit__c += objSingleTier.Flat_Price__c * objSingleTier.Monthly_Units_Purchased__c * monthsConsidered;
                                   }
                            }
                            system.debug('++flex '+objSingleDiscount.Total_Flex_Commit__c);
                        }
                    }
                }
            }
            Database.update(lstSingleDiscounts, false);
        }
    }
    
    //Method to calculate flex duration
    public static void updateFlexTierDuration(List<Single_BI_Tier__c> lstSingleTier, Set<Id> setAgreementIds, Boolean isAgreementUpdate){
        //map to hold agreement ID with its agreement term range
        Map<Id,Apttus__APTS_Agreement__c> mapAgrmtIdwithRange = new Map<Id,Apttus__APTS_Agreement__c>();
        List<Apttus__APTS_Agreement__c> lstAgreement = [Select Id, Commit_Start_Month__c ,APTS_Agreement_Effective_Date__c ,Term_Range__c,Apttus__Contract_End_Date__c
                                                        from Apttus__APTS_Agreement__c where Id IN: setAgreementIds
                                                        and (Commit_Frequency__c!='No Commit - PAYG' and Commit_Frequency__c!='No Commit - POC') and
                                                        (Commit_Start_Month__c!=null or APTS_Agreement_Effective_Date__c!=null or Apttus__Contract_End_Date__c!=null)
                                                        and Term_Range__c!=null];
        if(lstAgreement.size()>0){
            for(Apttus__APTS_Agreement__c objAgrmt: lstAgreement){
                mapAgrmtIdwithRange.put(objAgrmt.Id,objAgrmt);
            }
            
            system.debug('++mapAgrmtIdwithRange '+mapAgrmtIdwithRange);
            //Calculation
            for(Single_BI_Tier__c objSingleTier: lstSingleTier){
                if(objSingleTier.Last_Additional_Schedule__c==true){
                    objSingleTier.Flex_Tier_Duration__c= 0;
                }else
                {
                    //duration is months between start and end date
                    if(objSingleTier.Discount_Rate_Start_Date__c!=null && objSingleTier.Discount_Rate_End_Date__c!=null && mapAgrmtIdwithRange.size()>0){
                        if(mapAgrmtIdwithRange.get(objSingleTier.Agreement__c)!=null){
                            objSingleTier.Flex_Tier_Duration__c= Math.abs(objSingleTier.Discount_Rate_Start_Date__c.monthsBetween(objSingleTier.Discount_Rate_End_Date__c) 
                                                                          + Math.abs(((objSingleTier.Discount_Rate_Start_Date__c.day()-objSingleTier.Discount_Rate_End_Date__c.day())/27)));
                            
                        }else{
                            objSingleTier.Flex_Tier_Duration__c= 0;
                        }
                    }
                    //add agreement term range to tier row 1 start date and consider it as end date, find months between them 
                    else if(objSingleTier.Discount_Rate_Start_Date__c!=null && objSingleTier.Discount_Rate_End_Date__c==null && mapAgrmtIdwithRange.size()>0){
                        if(mapAgrmtIdwithRange.get(objSingleTier.Agreement__c)!=null){
                            Date agreementDate = mapAgrmtIdwithRange.get(objSingleTier.Agreement__c).Commit_Start_Month__c==null ? 
                                mapAgrmtIdwithRange.get(objSingleTier.Agreement__c).APTS_Agreement_Effective_Date__c : 
                            mapAgrmtIdwithRange.get(objSingleTier.Agreement__c).Commit_Start_Month__c;
                            System.debug('+++agree '+agreementDate);
                            if(agreementDate!=null){
                                Date endDate = mapAgrmtIdwithRange.get(objSingleTier.Agreement__c).Apttus__Contract_End_Date__c!=null ? mapAgrmtIdwithRange.get(objSingleTier.Agreement__c).Apttus__Contract_End_Date__c : 
                                mapAgrmtIdwithRange.get(objSingleTier.Agreement__c).Commit_Start_Month__c==null ? mapAgrmtIdwithRange.get(objSingleTier.Agreement__c).APTS_Agreement_Effective_Date__c.addMonths(Integer.valueof(mapAgrmtIdwithRange.get(objSingleTier.Agreement__c).Term_Range__c)) :
                                mapAgrmtIdwithRange.get(objSingleTier.Agreement__c).Commit_Start_Month__c.addMonths(Integer.valueof(mapAgrmtIdwithRange.get(objSingleTier.Agreement__c).Term_Range__c));
                                system.debug('++enddate '+enddate);
                                if(endDate!=null){
                                    objSingleTier.Flex_Tier_Duration__c= Math.abs(objSingleTier.Discount_Rate_Start_Date__c.monthsBetween(endDate) 
                                                                                  + Math.abs(((objSingleTier.Discount_Rate_Start_Date__c.day()- endDate.day())/27)));
                                }else{
                                    objSingleTier.Flex_Tier_Duration__c=0;
                                }
                            }else{
                                objSingleTier.Flex_Tier_Duration__c=0;
                            }
                        }else{
                            objSingleTier.Flex_Tier_Duration__c= 0;
                        }
                    }else{
                        objSingleTier.Flex_Tier_Duration__c= 0;
                    }
                }
                
                system.debug('++duration '+objSingleTier.Flex_Tier_Duration__c);
            }
            //Update single BI tiers on agreement effective date or commit start date update
            if(isAgreementUpdate==true){
                Database.update(lstSingleTier, false);
                Set<Id> setSingleDiscountIds = new Set<Id>();
                List<Single_BI_Discount__c> lstSingleDiscounts = [Select Id,agreement__c from Single_BI_Discount__c where agreement__c In: setAgreementIds];
                
                if(lstSingleDiscounts.size()>0){
                    for(Single_BI_Discount__c objSingleDiscount: lstSingleDiscounts){
                        setSingleDiscountIds.add(objSingleDiscount.Id);
                    }
                    updateSingleBIDiscount(setSingleDiscountIds);
                }
                List<Apttus__APTS_Agreement__c> lstAgreementWithTier = [Select Id,Apttus__Status__c,Apttus__Contract_End_Date__c ,Related_Opportunity_APTS__c,APTS_Agreement_Effective_Date__c,Standard_Process__c,Commit_Start_Month__c, 
                                                                        Term_Range__c,(Select Id,Discount_Rate_Start_Date__c,Discount_Rate_End_Date__c,Flex_Tier_Total__c, Flex_Tier_Duration__c, 
                                                                                       Flat_Price__c ,Monthly_Units_Purchased__c from Single_BI_Tiers__r where Last_Additional_Schedule__c=false and Product_Group__c='Flex'
                                                                                       order by Discount_Rate_Start_Date__c) 
                                                                        from Apttus__APTS_Agreement__c where (Commit_Start_Month__c!=null or APTS_Agreement_Effective_Date__c!=null or Apttus__Contract_End_Date__c!=null)
                                                                        and Term_Range__c!=null and Apttus__Status__c='Activated'
                                                                        and (Commit_Frequency__c!='No Commit - PAYG' and Commit_Frequency__c!='No Commit - POC')
                                                                        and Id IN: setAgreementIds];
                if(lstAgreementWithTier.size()>0){
                    updateOpportunities(lstAgreementWithTier);
                }
            }
        }
    }
    
    //Update opportunities 'Software Committed Bookings' fields related to Single BI tier's agreement
    public static void updateOpportunities(List<Apttus__APTS_Agreement__c> lstAgreementWithTier){
        Set<Id> setOppIds = new Set<Id>();
        List<Opportunity> lstUpdateOpp = new List<Opportunity>();
        for(Apttus__APTS_Agreement__c objAgreement: lstAgreementWithTier){
            setOppIds.add(objAgreement.Related_Opportunity_APTS__c);
        }
        Map<ID, Opportunity> mapOpp = new Map<ID, Opportunity>([SELECT Id,Software_Validation__c,Y1_Software_Committed_Bookings_Validated__c,
                                                                Y2_Software_Committed_Bookings_Validated__c ,Y3_Software_Committed_Bookings_Validated__c 
                                                                FROM Opportunity where id IN: setOppIds]);
        if(mapOpp.size()>0){
            for(Apttus__APTS_Agreement__c objAgreement: lstAgreementWithTier){
                if(objAgreement.Single_BI_Tiers__r.size()>0 && objAgreement.Standard_Process__c==true && 
                   objAgreement.APTS_Agreement_Effective_Date__c!=null && objAgreement.Term_Range__c != null && objAgreement.Apttus__Status__c=='Activated' && mapOpp.get(objAgreement.Related_Opportunity_APTS__c)!=null){
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
                           System.debug('+++monthsPassToSecondYr '+monthsPassToSecondYr);
                           System.debug('+++endDateSecondYr '+endDateSecondYr);
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
                           System.debug('+++monthsPassToSecondYr '+monthsPassToSecondYr);
                           System.debug('+++endDateSecondYr '+endDateSecondYr);
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
                           System.debug('+++monthsPassToThirdYr '+monthsPassToThirdYr);
                           System.debug('+++endDateThirdYr '+endDateThirdYr);
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
                       System.debug('+++y1 '+y1);
                       System.debug('+++y2 '+y2);
                       System.debug('+++y3 '+y3);
                       mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Y1_Software_Committed_Bookings_Validated__c=y1;
                       mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Y2_Software_Committed_Bookings_Validated__c=y2;
                       mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Y3_Software_Committed_Bookings_Validated__c=y3;
                       mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Software_Validation__c = 'False';
                       lstUpdateOpp.add(mapOpp.get(objAgreement.Related_Opportunity_APTS__c));
                   }else if(objAgreement.Standard_Process__c==false && mapOpp.get(objAgreement.Related_Opportunity_APTS__c)!=null){
                       mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Software_Validation__c = 'True';
                       mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Y1_Software_Committed_Bookings_Validated__c=null;
                       mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Y2_Software_Committed_Bookings_Validated__c=null;
                       mapOpp.get(objAgreement.Related_Opportunity_APTS__c).Y3_Software_Committed_Bookings_Validated__c=null;
                       lstUpdateOpp.add(mapOpp.get(objAgreement.Related_Opportunity_APTS__c));
                   }
            }
            
            Database.update(lstUpdateOpp, false);
        }
    }
}