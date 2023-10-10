// Initiative__c init = [SELECT Id, ActiveMinimumToContinue__c, Day__c, Repeats__c, Frequency__c, MaxSeats__c, AddThreshhold__c, InactiveParticipants__c, Duration__c, StartTime__c, DaysToPause__c, EventCount__c, CurrentEvent__c, UseActiveMinimums__c, ActiveMinimumToStart__c, ActiveParticipants__c FROM Initiative__c WHERE Id = 'a07Hs0000185BURIA2'];
// InitiativeEvent__c initEvent  = [SELECT Id, MaxSeats__c, Seats__c, Initiative__c, GoogleCalendarId__c, GoogleEventId__c FROM InitiativeEvent__c WHERE Initiative__c = 'a07Hs0000185KFFIA2'];
// TL_BC_AutomatedProcess.addInitiativeSeats(initEvent);
// TL_BC_AutomatedProcess.scheduleNextEvent(init);
// TL_BC_AutomatedProcess.checkCIH(new List<Ifnitiative__c>{init});
String email = '';
GoogleCalendar__c calendar = [SELECT Id, Default__c, GoogleId__c, GoogleToken__c FROM GoogleCalendar__c WHERE GoogleToken__r.Email__c = :email AND Default__c = true];
TL_BC_IEvent_Actions.updateAttendance(calendar.Id, calendar.GoogleToken__c);

// TL_BC_ScheduledProcess.init('a07Hs0000185KFFIA2'); 
// TL_BC_ISeat.sendRequest('95ed91oh9290o1f29aho38dp5c', 'sebastian.godoy@trackland.com', new List<String>{'jsebastiangcolorado@gmail.com'}, 'a02Hs000015YKLhIAO');
// ya29.a0AfB_byCRBgYffvOeTtzBfRSHG1MBHkNMSnBuUAv_8-ywGWp-HT48bYjb0S3oDTNpWxAib60XM4Pj1uTkZONSj-XPViOuVDOJvoCZQWRTbCp0Lp1PDNiGSUCQtiGdZojYPsa5P-K9ybDxVAzEsBvxnvdE5gmRYjLulJ5taCgYKAegSARMSFQGOcNnCKP0FBfsjEzMfYahh1VfXmA0171