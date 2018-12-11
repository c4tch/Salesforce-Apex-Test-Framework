/**
* File Name   : c_TestFactory_Users
* Description : TestFactory Framework, provides templates of User data
* Modification Log
* ============================================================================
* Ver   Date        Author                  Modification
*-----------------------------------------------------------------------------
* 0.1   7-12-2018   Matt Evans              Draft
* 
*/

public class c_TestFactory_Users {

    /*** Administrator ***/

    public class AdminUser extends c_TestFactoryMaker  {

        sObject defaults()
        {
            // Default object
            User rec = new User();

            // Default values
            rec.Alias = 'tp_Admin';
            rec.UserName = rec.Alias + '@tp.test.com';
            rec.ProfileId = c_OrgSettings.profileIdByName('System Administrator');
            //TODO: rec.UserRoleId = c_OrgSettings.roleIdByName('Administrator');

            rec.Email = rec.Alias + '@tp.test.com';
            rec.FirstName = 'Admin';
            rec.LastName = 'User';

            rec.EmailEncodingKey = EmailEncodingKey; // Context values taken from the Factory
            rec.LanguageLocaleKey = LanguageLocaleKey;
            rec.LocaleSidKey = LocaleSidKey;
            rec.TimeZoneSidKey = TimeZoneSidKey;

            return (sObject) rec;
        }
    }
//*/
}