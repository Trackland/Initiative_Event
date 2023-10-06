public class TL_BC_UpdateISStatus implements Schedulable{
  public static Id jobId;

  public void execute(SchedulableContext ctx) {
		init();
	}

  @Future(callout=true)
	public static void init(){
    Google_Token__c[] tokens = [SELECT Id, Access_Token__c, Refresh_Token__c FROM Google_Token__c];
    System.enqueueJob(new TL_BC_IEvent_Actions.UpdateAtt(tokens));
  }

  @InvocableMethod(label='Attendance scheduler' description='Attendance scheduler')
	public static void schedule(){
		TL_BC_UpdateISStatus operation = new TL_BC_UpdateISStatus();
    System.schedule('TL update attendance', '0 0 * * * ?', operation);
	}
}