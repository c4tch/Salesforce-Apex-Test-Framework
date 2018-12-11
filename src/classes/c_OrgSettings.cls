/**
* File Name   : c_OrgSettings
* Description : Provide a common location to query and cache common org set ups, ex. Profile ID's, Role Id's, common settings etc.
* Modification Log
* ============================================================================
* Ver   Date        Author                  Modification
*-----------------------------------------------------------------------------
* 0.1   7-12-2018   Matt Evans              Draft
*
* Notes
* ============================================================================
* Can improve on caching by moving to platform cache for methods using DML
* Also consider using custom metadata for Automation Control (currently commented out)
*/

public class c_OrgSettings {

    /****** Automation Control Settings ****** /
    // TODO: Example for extension of this class for trigger automation control
    public static boolean TRIGGERS_DONOTFIRE = getAutomation_TriggerSetting();
    private static boolean getAutomation_TriggerSetting()
    {
        TP_AutomationControl__c ctrl = TP_AutomationControl__c.getInstance();
        if (ctrl.trigger_DoNotFire__c) return true;
        return false;
    }

    /****** Test Settings ******/
    public static boolean BULKIFY_TESTS()
    {
        if (useLargeDataSetInTests==null)
        {
            useLargeDataSetInTests = FALSE;
            c_TestSetup__mdt[] ctrl = [SELECT ID, useLargeDataSetInTests__c, activeDate__c from c_TestSetup__mdt where activeDate__c=TODAY limit 1];
            if (ctrl.size()>0)
            {
                useLargeDataSetInTests = ctrl[0].useLargeDataSetInTests__c;
            }
        }
        return useLargeDataSetInTests;
    }
    private static boolean useLargeDataSetInTests;


    /****** Security Settings ******/

    // User Profile Id by Name
    public static id profileIdByName(String profileName) {
        if (profileIdsByName.containsKey(profileName)) return profileIdsByName.get(profileName);
        for (Profile p : [select id,Name from Profile])
        {
            profileIdsByName.put(p.Name,p.Id);
        }
        if (profileIdsByName.containsKey(profileName)) return profileIdsByName.get(profileName);
        return null;
    }
    private static Map<String, id> profileIdsByName = new Map<String, Id>();


    // Cached User Role Id by Name
    public static id roleIdByName(String roleName) {
        if (roleIdsByName.containsKey(roleName)) return roleIdsByName.get(roleName);
        for (UserRole r : [select id,Name from UserRole])
        {
            roleIdsByName.put(r.Name,r.Id);
        }
        if (roleIdsByName.containsKey(roleName)) return roleIdsByName.get(roleName);
        return null;
    }
    private static Map<String, id> roleIdsByName = new Map<String, Id>();

}