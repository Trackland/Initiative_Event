public with sharing class TL_BC_ISeat {
  
  public static void triggerISeat(InitiativeSeat__c[] newISeats, Map<Id, InitiativeSeat__c> oldISeatsMap){
    String[] conatctIds = new List<String>();
    String[] initEvent = new List<String>();
    Map<String, List<String>> eventContactsMap = new Map<String, List<String>>();
    for(InitiativeSeat__c iSeat : newISeats) {
      String[] contacts = eventContactsMap.get(iSeat.Initiative_Event__c);
      if(contacts == null) contacts = new List<String>();
      contacts.add(iSeat.Contact__c);
      eventContactsMap.put(iSeat.Initiative_Event__c, contacts);
      conatctIds.add(iSeat.Contact__c);
    }
    Map<String, String> contactEmailMap = new Map<String, String>();
    for(Contact con : [SELECT Id, Email FROM Contact WHERE Id IN :conatctIds]) contactEmailMap.put(con.Id, con.Email);
    Set<String> eventIds = eventContactsMap.keySet();
    for(InitiativeEvent__c event : [SELECT Id, GoogleCalendarId__c	, GoogleEventId__c FROM InitiativeEvent__c WHERE Id IN :eventIds]) {
      String[] contacts = eventContactsMap.get(event.Id);
      String[] emails = new List<String>();
      for(String conId : contacts) emails.add(contactEmailMap.get(conId));
      System.enqueueJob(new addGuest(event.GoogleEventId__c, event.GoogleCalendarId__c, emails));
    }
  }

  public class addGuest implements Queueable{
    String eventId;
    String calendarId;
    String[] emails;
    public addGuest(String eventId, String calendarId, String[] emails){
      this.eventId = eventId;
      this.calendarId = calendarId;
      this.emails = emails;
    }
    public void execute(QueueableContext context){
      TL_BC_ISeat.sendRequest(eventId, calendarId, emails);
    }

  }

  @future(callout=true)
  public static void sendRequest(String eventId, String calendarId, String[] emails){
    TL_SeatActions.addGuestToEvent(eventId, calendarId, emails);
  }
}