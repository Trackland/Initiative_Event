public class TL_BC_UpdateISStatus implements Schedulable{
  public static Id jobId;

  public void execute(SchedulableContext ctx) {
		init();
	}

  @Future(callout=true)
	public static void init(){
    GoogleCalendar__c calendar = [SELECT Id, Name, GoogleId__c FROM GoogleCalendar__c WHERE Default__c = true];
    TL_BC_IEvent_Actions.updateAttendance(calendar.Id);
  }

  @InvocableMethod(label='Attendance scheduler' description='Attendance scheduler')
	public static void schedule(){
		TL_BC_UpdateISStatus operation = new TL_BC_UpdateISStatus();
    System.schedule('TL update attendance', '0 0 * * * ?', operation);
	}
}