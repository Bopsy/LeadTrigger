global class CampaignMemberAutoConvertScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new CampaignMemberAutoConvert(),10);
    }
}