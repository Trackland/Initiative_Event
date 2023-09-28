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
      if(cih.SeatSinceAttendance__c >= init.AddThreshhold__c) {
        cihIds.add(cih.Contact__c);
        contactInitiative.put(cih.Contact__c, init);
      }
    }
    CampaignMember[] cmList = [SELECT Id, ContactId, CampaignId FROM CampaignMember WHERE ContactId IN :cihIds AND Id in :activeCampaignIds];
    for(CampaignMember cm: cmList){
      Initiative__c initiative = contactInitiative.get(cm.ContactId);
      cm.CampaignId = initiative.InactiveParticipants__c;
    }
    update cmList;
  }

  public static void scheduleFirstEvent(Initiative__c init){
    if(init.EventCount__c != 0 || init.CurrentEvent__c != null) return;
    if(!init.UseActiveMinimums__c){
      scheduleNewEvent(init);
      return;
    }
    CampaignMember[] cmList = [SELECT Id FROM CampaignMember WHERE CampaignId = :init.ActiveParticipants__c];
    if(init.UseActiveMinimums__c && init.ActiveMinimumToStart__c < cmList.size()) return;
    scheduleNewEvent(init);
  }

  public static void scheduleNewEvent(Initiative__c init){
    InitiativeEvent__c initEvent = new InitiativeEvent__c();
    initEvent.Initiative__c = init.Id;
    Datetime startTime = init.CurrentEvent__c != null ? init.CurrentEvent__c.addDays((Integer)init.DaysToPause__c) : System.today();
    initEvent.StartDate__c = Datetime.newInstance(startTime.year(), startTime.month(), startTime.day(), init.StartTime__c.hour(), init.StartTime__c.minute(), 0);
    initEvent.EndDate__c = initEvent.StartDate__c.addHours((Integer)init.Duration__c.hour()).addMinutes((Integer)init.Duration__c.minute());
    update initEvent;
  }

  public static void addInitiativeSeats(InitiativeEvent__c initEvent){
    if(initEvent.MaxSeats__c <= initEvent.Seats__c) return;
    Initiative__c initiative = [SELECT Id, AddThreshhold__c, ActiveParticipants__c FROM Initiative__c WHERE Id = :initEvent.Initiative__c];
    InitiativeSeat__c[] iSeatList = [SELECT Id, ContactInitiativeHistory__c FROM InitiativeSeat__c WHERE Initiative_Event__c = :initEvent.Id];
    Set<Id> iSeatIds = new Set<Id>();
    for(InitiativeSeat__c iSeat : iSeatList) iSeatIds.add(iSeat.ContactInitiativeHistory__c);
    CampaignMember[] cmList = [SELECT Id, ContactId FROM CampaignMember WHERE CampaignId = :initiative.ActiveParticipants__c AND ContactId NOT IN :iSeatIds];
    List<InitiativeSeat__c> newSeats = new List<InitiativeSeat__c>();
    Integer count = 0;
    if(initiative.AddThreshhold__c == null) initiative.AddThreshhold__c = 0;
    for(CampaignMember cm : cmList){
      if(count > initiative.AddThreshhold__c) break;
      InitiativeSeat__c iSeat = new InitiativeSeat__c();
      iSeat.Initiative_Event__c = initEvent.Id;
      iSeat.Contact__c = cm.ContactId;
      newSeats.add(iSeat);
    }
    insert newSeats;
  }

  public static void scheduleNextEvent(Initiative__c init){
    if(System.today() <= init.CurrentEvent__c.addDays((Integer)init.DaysToPause__c)) return;
    if(!init.UseActiveMinimums__c){
      scheduleNewEvent(init);
      return;
    }
    CampaignMember[] cmList = [SELECT Id FROM CampaignMember WHERE CampaignId = :init.ActiveParticipants__c];
    if(init.EventCount__c < 1 || init.ActiveMinimumToContinue__c < cmList.size()) return;
    scheduleNewEvent(init);
  }

}