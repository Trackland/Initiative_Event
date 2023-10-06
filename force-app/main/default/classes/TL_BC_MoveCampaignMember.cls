public with sharing class TL_BC_MoveCampaignMember {
  
  @InvocableMethod(label='Move Campaign Members' description='Moves the specified campaign members to the specified campaign.')
  public static String[] moveCampaignMember(methodVariable[] variables) {
    String[] newCMIds = new list<String> ();
    String[] notUse = new list<String> {'isdeleted', 'id', 'campaignid', 'lastmodifieddate', 'lastmodifiedbyid', 'systemmodstamp'};
    for(methodVariable variable : variables) {
      CampaignMember campaignMember = variable.campaignMember;
      CampaignMember newCM = new CampaignMember(CampaignId=variable.newCampaignId, ContactId=campaignMember.ContactId, LeadId=campaignMember.LeadId);
      SObjectType accountType = Schema.getGlobalDescribe().get('CampaignMember');
      Map<String,Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();
      Map<String, Object> fields = campaignMember.getPopulatedFieldsAsMap();
      for(String fieldName : fields.keySet()) {
        Schema.DescribeFieldResult dfr = mfields.get(fieldName).getDescribe();
        if(!dfr.isUpdateable()) continue;
        newCM.put(fieldName, campaignMember.get(fieldName));
      }
      delete campaignMember;
      insert newCM;
      newCMIds.add(newCM.Id);
    }
    return newCMIds;
  }

  public class methodVariable {
    @InvocableVariable(label='Campaign Member' description='The campaign member to move.' required=true)
    public CampaignMember campaignMember;

    @InvocableVariable(label='New Campaign Id' description='The Id of the campaign to move the campaign member to.' required=true)
    public Id newCampaignId;
  }
}