public with sharing class TL_BC_AutomatedProcess {

  public static void checkCIH(Initiative__c[] initList){
    Set<Id> initIds = new Set<Id>();
    Set<Id> activeCampaignIds = new Set<Id>();
    Set<Id> inactiveCampaignIds = new Set<Id>();
    Map<Id, Initiative__c> initiativeMap = new Map<Id, Initiative__c>(initList);
    for(Initiative__c init : initList){
      initIds.add(init.Id);
      activeCampaignIds.add(init.ActiveParticipants__c);
      inactiveCampaignIds.add(init.InactiveParticipants__c);
    }
    InitiativeEvent__c[] iEventList = [SELECT Id, Initiative__c FROM InitiativeEvent__c WHERE Initiative__c IN :initIds];
    Set<Id> iEventIds = new Set<Id>();
    Map<Id, Id> initiativeEventInit = new Map<Id, Id>();
    for(InitiativeEvent__c iEvent : iEventList) {
      iEventIds.add(iEvent.Id);
      initiativeEventInit.put(iEvent.Id, iEvent.Initiative__c);
    }
    InitiativeSeat__c[] iSeatList = [SELECT Id, Initiative_Event__c, ContactInitiativeHistory__c FROM InitiativeSeat__c WHERE Initiative_Event__c IN :iEventIds];
    Set<Id> iSeatIds = new Set<Id>();
    Map<Id, Id> initiativeSeatInit = new Map<Id, Id>();
    for(InitiativeSeat__c iSeat : iSeatList) {
      iSeatIds.add(iSeat.ContactInitiativeHistory__c);
      initiativeSeatInit.put(iSeat.ContactInitiativeHistory__c, initiativeEventInit.get(iSeat.Initiative_Event__c));
    }
    ContactInitiativeHistory__c[] cihList = [SELECT Id, SeatSinceAttendance__c, Contact__c FROM ContactInitiativeHistory__c WHERE Id IN :iSeatIds];
    Set<Id> cihIds = new Set<Id>();
    Map<Id, Initiative__c> contactInitiative = new Map<Id, Initiative__c>(initList);
    for(ContactInitiativeHistory__c cih : cihList) {
      Id initId = initiativeSeatInit.get(cih.Id);
      Initiative__c init = initiativeMap.get(initId);
      if(cih.SeatSinceAttendance__c < init.AddThreshhold__c) continue;
      cihIds.add(cih.Contact__c);
      contactInitiative.put(cih.Contact__c, init);
    }
    CampaignMember[] cmList = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId IN :cihIds AND Id in :activeCampaignIds];
    for(CampaignMember cm: cmList){
      Initiative__c initiative = contactInitiative.get(cm.ContactId);
      cm.CampaignId = initiative.InactiveParticipants__c;
    }
    update cmList;
  }

  public static void scheduleNewEvent(Initiative__c init){
    InitiativeEvent__c initEvent = new InitiativeEvent__c();
    initEvent.Initiative__c = init.Id;
    Datetime startTime = init.CurrentEvent__c != null ? (Datetime) init.CurrentEvent__c.addDays((Integer)init.DaysToPause__c) : init.StartTime__c;
    if(init.CurrentEvent__c == null){
      if(init.Repeats__c == 'Weekly' && startTime.format('EEEE') == init.Day__c) startTime.addDays(-1);
      else if(init.Repeats__c == 'Monthly') startTime = startTime.addMonths(-1);
      else if(init.Repeats__c == 'Quarterly') startTime = startTime.addMonths(-4);
    }
    Integer weekDay = init.Frequency__c == null ? 0 : Integer.valueOf(init.Frequency__c.split(' ')[1]);
    if(init.Repeats__c != null && init.Day__c == null) throw new TL_BC_AutomatedProcessException('you need specify a day of the week to repeat this event');
    if(init.Repeats__c == null && init.Day__c != null) throw new TL_BC_AutomatedProcessException('you need specify a repeats frequency to repeat this event');
    if(init.Repeats__c == 'Weekly') initEvent.StartDate__c = getNextWeekDate(init.Day__c, startTime);
    else if(init.Repeats__c == 'Monthly') initEvent.StartDate__c = getNextDate(weekDay, init.Day__c, startTime.date().addMonths(1), startTime.time());
    else if(init.Repeats__c == 'Quarterly') initEvent.StartDate__c = getNextDate(weekDay, init.Day__c, startTime.date().addMonths(4), startTime.time());
    if(init.Duration__c == null) throw new TL_BC_AutomatedProcessException('The initiative duration should be set');
    initEvent.EndDate__c = initEvent.StartDate__c.addMinutes((Integer)init.Duration__c);
    initEvent.MaxSeats__c = init.MaxSeats__c;
    initEvent.Name = init.Name + ' - ' + initEvent.StartDate__c.format('MMM dd yyyy');
    insert initEvent;
    init.CurrentEvent__c = Date.valueOf(initEvent.StartDate__c);
    update init;
  }

  public static Datetime getNextWeekDate(String weekDay, Datetime startDate){
    DateTime myDateTime = startDate;
    myDateTime = Datetime.newInstance(System.today(), myDateTime.time());
    System.debug(startDate.time());
    while (myDateTime.format('EEEE') != weekDay) myDateTime = myDateTime.addDays(1);
    return myDateTime;
  }

  public static Datetime getNextDate(Integer weekNumber, String weekDay, Date startDate, Time timeDate){
    if(weekNumber == 0) throw new TL_BC_AutomatedProcessException('you need to specify a frequency');
    Map<String, Integer> daysMap = new Map<String, Integer>{'Monday'=>1, 'Tuesday'=>2, 'Wednesday'=>3, 'Thursday'=>4, 'Friday'=>5, 'Saturday'=>6, 'Sunday'=>7};
    DateTime startOfMonth = startDate.toStartOfMonth();
    Integer startWeek = Integer.valueOf(startOfMonth.format('w'));
    DateTime finalDate = startOfMonth.addDays(7*(weekNumber-1));
    Date finalDate2 = finalDate.date().toStartOfWeek();
    return Datetime.newInstanceGMT(finalDate2, timeDate).addDays(daysMap.get(weekDay));
  }

  public static void addInitiativeSeats(InitiativeEvent__c initEvent){
    if(initEvent.MaxSeats__c <= initEvent.Seats__c) return;
    Initiative__c initiative = [SELECT Id, AddThreshhold__c, ActiveParticipants__c, Name, MaxSeats__c FROM Initiative__c WHERE Id = :initEvent.Initiative__c];
    InitiativeSeat__c[] iSeatList = [SELECT Id, Contact__c FROM InitiativeSeat__c WHERE Initiative_Event__c = :initEvent.Id];
    Set<Id> iSeatIds = new Set<Id>();
    for(InitiativeSeat__c iSeat : iSeatList) iSeatIds.add(iSeat.Contact__c);
    if(iSeatIds.size() >= initiative.MaxSeats__c) return;
    Integer maxSeats = (Integer) initiative.MaxSeats__c - iSeatIds.size();
    Integer max = initiative.AddThreshhold__c == null ? 0 : (Integer)initiative.AddThreshhold__c;
    if(max > maxSeats) max = maxSeats;
    CampaignMember[] cmList = [SELECT Id, ContactId FROM CampaignMember WHERE CampaignId = :initiative.ActiveParticipants__c AND ContactId NOT IN :iSeatIds LIMIT :max];
    List<InitiativeSeat__c> newSeats = new List<InitiativeSeat__c>();
    Id[] campaignMemberContacts = new List<Id>();
    for(CampaignMember cm : cmList) campaignMemberContacts.add(cm.ContactId);
    Map<String,Id> cihMap = getContactHistories(campaignMemberContacts, initiative.Id);
    for(CampaignMember cm : cmList){
      InitiativeSeat__c iSeat = new InitiativeSeat__c();
      iSeat.Initiative_Event__c = initEvent.Id;
      iSeat.Contact__c = cm.ContactId;
      iSeat.ContactInitiativeHistory__c = cihMap.get(cm.ContactId);
      newSeats.add(iSeat);
    }
    insert newSeats;
  }

  public static Map<String,Id> getContactHistories(Id[] contactIds, String initId){
    ContactInitiativeHistory__c[] cihList = [SELECT Id, Contact__c, SeatSinceAttendance__c FROM ContactInitiativeHistory__c WHERE Contact__c IN :contactIds AND Initiative__c = :initId];
    Set<Id> notExisting = new Set<Id>();
    Map<String,Id> contactHistoryMap = new Map<String,Id>();
    for(ContactInitiativeHistory__c cih : cihList) contactHistoryMap.put(cih.Contact__c, cih.Id);
    for(Id contactId : contactIds) if(contactHistoryMap.get(contactId) == null) notExisting.add(contactId);
    Contact[] contactList = [SELECT Id, Name FROM Contact WHERE Id IN :notExisting];
    ContactInitiativeHistory__c[] newCihList = new List<ContactInitiativeHistory__c>();
    for(Contact contact : contactList) newCihList.add(new ContactInitiativeHistory__c(Contact__c = contact.Id, Initiative__c = initId));
    insert newCihList;
    cihList.addAll(newCihList);
    for(ContactInitiativeHistory__c cih : cihList) contactHistoryMap.put(cih.Contact__c, cih.Id);
    return contactHistoryMap;
  }

  public static void scheduleNextEvent(Initiative__c init){
    if(init.CurrentEvent__c != null && System.today() <= init.CurrentEvent__c.addDays((Integer)init.DaysToPause__c)) return;
    CampaignMember[] cmList = [SELECT Id FROM CampaignMember WHERE CampaignId = :init.ActiveParticipants__c];
    Boolean isFirstEvent = init.EventCount__c == 0 || init.EventCount__c == null;
    Boolean notUseMinimums = !init.UseActiveMinimums__c;
    Boolean haveMinimumToContinue = init.ActiveMinimumToContinue__c <= cmList.size();
    if(init.Email__c == null) throw new TL_BC_AutomatedProcessException('You need to specify an email to schedule new events');
    if(isFirstEvent || notUseMinimums || haveMinimumToContinue) scheduleNewEvent(init);
  }

  public class TL_BC_AutomatedProcessException extends Exception {}
}