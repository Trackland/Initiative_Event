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
    InitiativeEvent__c[] events = [SELECT Id, GoogleCalendarId__c	, GoogleEventId__c FROM InitiativeEvent__c WHERE Id IN :eventIds];
    String[] calendarIds = new List<String>();
    for(InitiativeEvent__c event : events) calendarIds.add(event.GoogleCalendarId__c);
    GoogleCalendar__c[] calendars = [SELECT Id, GoogleToken__c, GoogleId__c FROM GoogleCalendar__c WHERE GoogleId__c IN :calendarIds];
    String[] tokenIds = new List<String>();
    for(GoogleCalendar__c calendar : calendars) tokenIds.add(calendar.GoogleToken__c);
    Google_Token__c[] tokens = [SELECT Id, Access_Token__c, Refresh_Token__c FROM Google_Token__c WHERE Id IN :tokenIds];
    Map<String, Google_Token__c> tokenMap = new Map<String, Google_Token__c>();
    for(Google_Token__c token : tokens) tokenMap.put(token.Id, token);
    for(GoogleCalendar__c calendar : calendars)  {
      tokenMap.put(calendar.GoogleId__c, tokenMap.get(calendar.GoogleToken__c));
      System.enqueueJob(new TokenManagement(calendar.GoogleToken__c));
    }
    for(InitiativeEvent__c event : events) {
      Google_Token__c token = tokenMap.get(event.GoogleCalendarId__c);
      String[] contacts = eventContactsMap.get(event.Id);
      String[] emails = new List<String>();
      for(String conId : contacts) emails.add(contactEmailMap.get(conId));
      if(event.GoogleEventId__c == null || event.GoogleCalendarId__c == null) continue;
      System.enqueueJob(new addGuest(event.GoogleEventId__c, event.GoogleCalendarId__c, emails, token));
    }
  }

  public class addGuest implements Queueable, Database.AllowsCallouts{
    String eventId;
    String calendarId;
    String[] emails;
    Google_Token__c token;

    public addGuest(String eventId, String calendarId, String[] emails, Google_Token__c token){
      this.eventId = eventId;
      this.calendarId = calendarId;
      this.emails = emails;
      this.token = token;
    }
    public void execute(QueueableContext context){
      TL_BC_ISeat.sendRequest(eventId, calendarId, emails, token.Id);
    }

  }

  public static void sendRequest(String eventId, String calendarId, String[] emails, String tokenId){
    Google_Token__c token = [SELECT Access_Token__c, Refresh_Token__c, Expires_In__c FROM Google_Token__c WHERE Id = :tokenId];
    TL_SeatActions.addGuestToEvent(eventId, calendarId, emails, token);
  }

  public class TokenManagement implements Queueable, Database.AllowsCallouts{
    String tokenId;

    public TokenManagement(String tokenId){
      this.tokenId = tokenId;
    }

    public void execute(QueueableContext context){
      Google_Token__c token = [SELECT Id, Access_Token__c, Refresh_Token__c, Expires_In__c FROM Google_Token__c WHERE Id = :this.tokenId];
      if(token.Expires_In__c > DateTime.now().addSeconds(60)) return;
      token = GenericConnectorController.doRefreshTokenStatic(token);
      update token;
    }
  }
}