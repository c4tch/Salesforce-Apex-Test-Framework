/**
 @Name: c_TestFactory_CoreUsers.cls
 @TestedBy: Implementing in a test class
 @Description:
  TestFactory Framework, provides templates of User data
 @History
  VERSION     AUTHOR           DATE            DETAIL
  1.0         Matt Evans       7/12/2018       System Admin basic user for common classes to use
*/

public class c_TestFactory_CoreUsers {

    /**
    * Administrator 
    **/
    public class StandardSystemAdmin extends c_TestFactoryMaker  {

        sObject defaults()
        {
            // Default object
            User rec = new User();
            String orgId = UserInfo.getOrganizationId();
            
            // Default values
            rec.Alias = 'SysAdmin';
            rec.UserName = rec.Alias + '@'+ orgId+'.any.test.com';
            rec.ProfileId = c_Describe.profileIdByName('System Administrator');

            rec.Email = rec.Alias + '@any.test.com';
            rec.FirstName = 'Admin';
            rec.LastName = 'User';

            rec.EmailEncodingKey = EMAIL_ENCODING_KEY; // Context values taken from the Factory
            rec.LanguageLocaleKey = LANGUAGE_LOCALE_KEY;
            rec.LocaleSidKey = LOCALE_SID_KEY;
            rec.TimeZoneSidKey = TIMEZONE_SID_KEY;

            return (sObject) rec;
        }
    }
}