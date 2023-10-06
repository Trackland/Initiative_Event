public with sharing class TL_BC_IEvent_Actions {

  @Future(callout=true)
  public static void updateAttendance(String calendarId){
    // GenericConnectorController.doRefreshTokenStatic();
    GoogleCalendar__c calendar = [SELECT Id, Name, GoogleId__c FROM GoogleCalendar__c WHERE Id = :calendarId];
    Map<string, Object> res = (Map<String,Object>) TL_EventActions.getCommingEvents(calendar.GoogleId__c);
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
    GoogleCalendar__c calendar = [SELECT Id, GoogleId__c FROM GoogleCalendar__c WHERE Default__c = true];
    for(InitiativeEvent__c event: events) createGoogleEvent(event.Id, calendar.GoogleId__c);
  }

  @future(callout=true)
  public static void createGoogleEvent(String eventId, String calendarId){
    InitiativeEvent__c event = [SELECT Id, Name, StartDate__c, EndDate__c, GoogleEventId__c FROM InitiativeEvent__c WHERE Id = :eventId];
    Map<String, Object> res = (Map<String, Object>) JSON.deserializeUntyped(TL_EventActions.createEvent(calendarId, event.Name, event.StartDate__c, event.EndDate__c));
    event.GoogleCalendarId__c = calendarId;
    event.GoogleEventId__c = (String) res.get('id');
    update event;
  }

  @future(callout=true)
  public static void deleteGoogleEvent(String eventId, String calendarId){
    TL_EventActions.deleteEvent(eventId, calendarId);
  }
}