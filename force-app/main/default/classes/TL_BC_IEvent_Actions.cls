public class TL_BC_IEvent_Actions {

  public class UpdateAtt implements Queueable{
    Google_Token__c[] tokens;

    public UpdateAtt(Google_Token__c[] tokens){
      this.tokens = tokens;
    }

    public void execute(QueueableContext context){
      Google_Token__c token = tokens.remove(0);
      GoogleCalendar__c[] calendars = [SELECT Id, Name, GoogleId__c FROM GoogleCalendar__c WHERE GoogleToken__c = :token.Id AND Default__c = true];
      System.enqueueJob(new updateAtt(tokens));
      if(calendars.size() == 0) return;
      GoogleCalendar__c calendar = calendars[0];
      updateAttendance(calendar.Id, token.Id);
    }
  }

  @Future(callout=true)
  public static void updateAttendance(String calendarId, String tokenId){
    Google_Token__c token = [SELECT Id, Refresh_Token__c, Access_Token__c FROM Google_Token__c WHERE Id = :tokenId];
    GoogleCalendar__c calendar = [SELECT Id, Name, GoogleId__c FROM GoogleCalendar__c WHERE Id = :calendarId];
    Map<string, Object> res = (Map<String,Object>) TL_EventActions.getCommingEvents(calendar.GoogleId__c, token);
    List<Object> events = (List<Object>) res.get('items');
    if(events == null) return;
    Map<String, Map<String, String>> eventAttendanceStatus = new Map<String, Map<String, String>>();
    for(Object eventO: events){
      Map<String,Object> event =  (Map<String,Object>) eventO;
      List<Object> attendees = (List<Object>)event.get('attendees');
      if(attendees == null || attendees.size() == 0) continue;
      Map<String, String> attendanceStatus = new Map<String, String>();
      for(Object attendeeO: attendees){
        Map<String,Object> attendee = (Map<String,Object>) attendeeO;
        attendanceStatus.put((String) attendee.get('email'), (String) attendee.get('responseStatus'));
      }
      eventAttendanceStatus.put((String) event.get('id'), attendanceStatus);
    }
    Set<String> eventIds = eventAttendanceStatus.keySet();
    InitiativeSeat__c[] seats = [SELECT Id, Status__c, Contact__r.Email, Initiative_Event__r.GoogleEventId__c FROM InitiativeSeat__c WHERE Initiative_Event__r.GoogleEventId__c in :eventIds];
    InitiativeSeat__c[] updatedSeats = new List<InitiativeSeat__c>();
    for(InitiativeSeat__c seat: seats){
      Map<String, String> attendanceStatus = eventAttendanceStatus.get(seat.Initiative_Event__r.GoogleEventId__c);
      String status = attendanceStatus.get(seat.Contact__r.Email);
      System.debug(status+' '+seat.Contact__r.Email);
      if(status == 'needsAction') status = 'No Response';
      if(status == 'accepted') status = 'Yes';
      if(status == 'declined') status = 'No';
      if(status == 'tentative') status = 'Maybe';
      if(seat.Status__c == status) continue;
      seat.Status__c = status;
      updatedSeats.add(seat);
    }
    update seats;
  }

  @InvocableMethod(label='Create Event' description='Create Event')
  public static void createEvent(InitiativeEvent__c[] events){
    Set<String> initIds = new Set<String>();
    for(InitiativeEvent__c event: events) initIds.add(event.Initiative__c);
    Initiative__c[] initiatives = [SELECT Id, Email__c FROM Initiative__c WHERE Id = :initIds];
    String[] emails = new List<String>();
    Map<Id, Initiative__c> initiativeMap = new Map<Id, Initiative__c>(initiatives);
    for(Initiative__c init: initiatives) emails.add(init.Email__c);
    GoogleCalendar__c[] calendars = [SELECT Id, Name, GoogleId__c, GoogleToken__c FROM GoogleCalendar__c WHERE GoogleToken__r.Email__c in :emails];
    Map<String, GoogleCalendar__c> calendarMap = new Map<String, GoogleCalendar__c>();
    for(GoogleCalendar__c calendar: calendars) calendarMap.put(calendar.GoogleId__c, calendar);
    for(InitiativeEvent__c event: events) {
      Initiative__c init = initiativeMap.get(event.Initiative__c);
      GoogleCalendar__c calendar = calendarMap.get(init.Email__c);
      createGoogleEvent(event.Id, calendar.GoogleId__c, calendar.GoogleToken__c);
    }
  }

  @future(callout=true)
  public static void createGoogleEvent(String eventId, String calendarId, String tokenId){
    Google_Token__c token = [SELECT Id, Access_Token__c, Refresh_Token__c FROM Google_Token__c WHERE Id = :tokenId];
    InitiativeEvent__c event = [SELECT Id, Name, StartDate__c, EndDate__c, GoogleEventId__c FROM InitiativeEvent__c WHERE Id = :eventId];
    Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(TL_EventActions.createEvent(calendarId, event.Name, event.StartDate__c, event.EndDate__c, token));
    event.GoogleCalendarId__c = calendarId;
    event.GoogleEventId__c = (String) res.get('id');
    update event;
  }

  @future(callout=true)
  public static void deleteGoogleEvent(String eventId, String calendarId){
    GoogleCalendar__c calendar = [SELECT Id, GoogleId__c, GoogleToken__c FROM GoogleCalendar__c WHERE GoogleId__c = :calendarId];
    Google_Token__c token = [SELECT Id, Access_Token__c, Refresh_Token__c FROM Google_Token__c WHERE Id = :calendar.GoogleToken__c];
    TL_EventActions.deleteEvent(eventId, calendarId, token);
  }
}