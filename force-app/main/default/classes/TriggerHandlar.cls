//Created by: Gram Bischof 10/2/2020
//Last Modified: Gram Bischof 10/2/2020
//
//Description: 
//This abstract class is used to define abstract method which overrides by EventCertificationTrigger_Handlar class methods. 
/**********************************************************/

public abstract class TriggerHandlar {
public TriggerHandlar() {}
    
    public abstract void executeBeforeInsert();   
    
    public abstract void updatePartnerInfluencer();
    
}