global class EmailDomainLeadAutoConvertScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
		EmailDomainLeadAutoConvert batch = new EmailDomainLeadAutoConvert();
//		batch.processRecordsOlderThan = 24;
        Database.executeBatch(batch,10);
    }
}