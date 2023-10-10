@IsTest
public with sharing class TL_BC_Tests {
  @TestSetup
  static void makeData(){
    Google_Token__c token = new Google_Token__c(
      Access_Token__c = 'sada',
      Refresh_Token__c = 'dasd',
      Expires_In__c = System.today().addDays(1),
      Email__c = 'test@test.com'
    );

    Contact contact1 = new Contact(
      FirstName = 'Test',
      LastName = 'Contact 1',
      Email = 'email@test.com'
    );

    Initiative__c initiativeWeekly = new Initiative__c(
      Name = 'Test Initiative Weekly',
      AddThreshhold__c = 1,
      MaxSeats__c = 3,
      UseActiveMinimums__c = true,
      ActiveMinimumToContinue__c = 1,
      Email__c = 'test@test.com',
      DaysToPause__c = 1,
      StartTime__c = System.now(),
      Repeats__c = 'Weekly',
      Day__c = System.now().addDays(1).format('EEEE'),
      Frequency__c = 'Week 1',
      Duration__c = 30
    );

    Initiative__c initiativeMonthly = new Initiative__c(
      Name = 'Test Initiative Monthly',
      AddThreshhold__c = 1,
      MaxSeats__c = 3,
      UseActiveMinimums__c = true,
      ActiveMinimumToContinue__c = 1,
      Email__c = 'test@test.com',
      DaysToPause__c = 1,
      StartTime__c = System.now(),
      Repeats__c = 'Monthly',
      Day__c = System.now().addDays(1).format('EEEE'),
      Frequency__c = 'Week 1',
      Duration__c = 30
    );
    insert new List<sObject>{token, initiativeWeekly, initiativeMonthly, contact1};

    GoogleCalendar__c gc = new GoogleCalendar__c(
      Name = 'Test Calendar',
      GoogleId__c = 'sadas',
      GoogleToken__c = token.Id,
      Default__c = true
    );
    Campaign activeMonthly = new Campaign(Name = 'Test Campaign Monthly');
    Campaign activeWeekly = new Campaign(Name = 'Test Campaign Weekly');
    insert new List<sObject>{gc, activeWeekly, activeMonthly};

    initiativeWeekly.ActiveParticipants__c = activeWeekly.Id;
    initiativeMonthly.ActiveParticipants__c = activeMonthly.Id;
    update new List<sObject>{initiativeWeekly, initiativeMonthly};

    CampaignMember cmW = new CampaignMember(
      CampaignId = activeWeekly.Id,
      ContactId = contact1.Id,
      Status = 'Attended'
    );
    CampaignMember cmM = new CampaignMember(
      CampaignId = activeMonthly.Id,
      ContactId = contact1.Id,
      Status = 'Attended'
    );
    insert new List<sObject>{cmW, cmM};
  }

  @IsTest
  public static void automatedProcess_Test(){
    Initiative__c[] inits = [SELECT Id FROM Initiative__c];
    for(Initiative__c init: inits) TL_BC_ScheduledProcess.init(init.Id);
    for(Initiative__c init: inits) TL_BC_ScheduledProcess.init(init.Id);
  }

  @IsTest
  public static void scheduledProcess_Test(){
    Initiative__c[] inits = [SELECT Id FROM Initiative__c];
    try {
      TL_BC_ScheduledProcess.schedule(inits);
    } catch (Exception e) {}
  }

  @IsTest
  public static void iSeat_Test(){
    Google_Token__c token = [SELECT Id FROM Google_Token__c limit 1];
    Test.startTest();
    System.enqueueJob(new TL_BC_iSeat.addGuest('eventId', 'calendarId', new List<String>{'test@test.com'}, token));
    Test.stopTest();
  }

  @IsTest
  public static void iEventAttendanceClass_Test(){
    Google_Token__c[] tokens = [SELECT Id FROM Google_Token__c];
    Test.startTest();
    System.enqueueJob(new TL_BC_IEvent_Actions.UpdateAtt(tokens));
    Test.stopTest();
  }

  @IsTest
  public static void iEventAttendance_Test(){
    Google_Token__c token = [SELECT Id FROM Google_Token__c limit 1];
    GoogleCalendar__c gc = [SELECT Id FROM GoogleCalendar__c limit 1];
    Test.startTest();
    TL_BC_IEvent_Actions.updateAttendance(gc.Id, token.Id);
    Test.stopTest();
  }

  @IsTest
  public static void googleEventQueueCreate_Test(){
    Initiative__c inits = [SELECT Id FROM Initiative__c limit 1];
    InitiativeEvent__c event = new InitiativeEvent__c(
      Name = 'Test Event',
      Initiative__c = inits.Id,
      StartDate__c = System.now(),
      EndDate__c = System.now().addHours(1)
    );
    insert event;
    Google_Token__c token = [SELECT Id FROM Google_Token__c limit 1];
    GoogleCalendar__c gc = [SELECT Id FROM GoogleCalendar__c limit 1];
    Test.startTest();
    System.enqueueJob(new TL_BC_IEvent_Actions.GoogleEventQueue(event.Id, gc.Id, token.Id, 'CREATE'));
    Test.stopTest();
  }

  @IsTest
  public static void googleEventQueueDelete_Test(){
    Initiative__c inits = [SELECT Id FROM Initiative__c limit 1];
    InitiativeEvent__c event = new InitiativeEvent__c(
      Name = 'Test Event',
      Initiative__c = inits.Id,
      StartDate__c = System.now(),
      EndDate__c = System.now().addHours(1)
    );
    insert event;
    Google_Token__c token = [SELECT Id FROM Google_Token__c limit 1];
    GoogleCalendar__c gc = [SELECT Id FROM GoogleCalendar__c limit 1];
    Test.startTest();
    System.enqueueJob(new TL_BC_IEvent_Actions.GoogleEventQueue(event.Id, gc.Id, token.Id, 'DELETE'));
    Test.stopTest();
  }
}