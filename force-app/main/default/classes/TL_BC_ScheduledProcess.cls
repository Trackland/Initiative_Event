public class TL_BC_ScheduledProcess implements Schedulable {
  public static Id jobId;
  public Id initId;

  public TL_BC_ScheduledProcess(Id initId){
    this.initId = initId;
  }

	public void execute(SchedulableContext ctx) {
		init(this.initId);
	}

	public static void init(Id initId){
    Initiative__c init = [SELECT Id, Name, ActiveMinimumToContinue__c, Day__c, Repeats__c, Frequency__c, MaxSeats__c, AddThreshhold__c, InactiveParticipants__c, Duration__c, StartTime__c, DaysToPause__c, EventCount__c, CurrentEvent__c, UseActiveMinimums__c, ActiveMinimumToStart__c, ActiveParticipants__c FROM Initiative__c WHERE Id = :initId];
    InitiativeEvent__c[] initEvents = [SELECT Id, MaxSeats__c, Seats__c, Initiative__c, GoogleCalendarId__c, GoogleEventId__c FROM InitiativeEvent__c WHERE Initiative__c = :initId];
    for(InitiativeEvent__c initEvent: initEvents) TL_BC_AutomatedProcess.addInitiativeSeats(initEvent);
    TL_BC_AutomatedProcess.scheduleNextEvent(init);
    TL_BC_AutomatedProcess.checkCIH(new List<Initiative__c>{ init });
	}

  @InvocableMethod(label='Initiative Automation' description='Initiative Automation')
	public static void schedule(Initiative__c[] inits){
    Initiative__c init = inits[0];
		TL_BC_ScheduledProcess operation = new TL_BC_ScheduledProcess(init.Id);
    System.schedule('TL IE Initiative '+init.Name, '0 0 * * * ?', operation);
	}
}