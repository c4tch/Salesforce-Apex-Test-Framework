/**
 @Name: c_TestFactory_Users.cls
 @TestedBy: Implementing in a test class
 @Description:
  TestFactory Framework, provides templates of User data
 @History
  VERSION     AUTHOR           DATE            DETAIL
  1.0         Matt Evans       7/12/2018       Draft
  1.1         Matt Evans       9/9/2019        Added a business user that allows user name overwriting using Alias when set
*/

public class c_TestFactory_Users {

    /**
    * Country User 
    **/
    public class CountryUser extends c_TestFactoryMaker  {

        sObject defaults()
        {
            // Default object
            User rec = new User();
            String orgId = UserInfo.getOrganizationId();
            
            // Default values
            rec.Alias = 'country';
            rec.UserName = rec.Alias + '@'+ orgId+'.test.com';
            rec.ProfileId = c_Describe.profileIdByName('Standard User');

            rec.Email = rec.Alias + '@some.test.com';
            rec.FirstName = 'Country';
            rec.LastName = 'User';

            rec.EmailEncodingKey = EMAIL_ENCODING_KEY; // Context values taken from the Factory
            rec.LanguageLocaleKey = LANGUAGE_LOCALE_KEY;
            rec.LocaleSidKey = LOCALE_SID_KEY;
            rec.TimeZoneSidKey = TIMEZONE_SID_KEY;

            return (sObject) rec;
        }

        // Custom maker method so we can apply some logic to the default values based on the source object
        public override sObject make(sObject sourceObject) {
            
            // Process the custom create method
            sObject rec = defaults();

            // Merge default values into passed object
            // - Fields set on the inbound sourceObject record will be preserved
            sourceObject = mergeFields(rec, sourceObject);

            // Custom logic to Update the username based on Alias if it's not the same as the default
            if (((User)sourceObject).Alias!=null && ((User)sourceObject).username == ((User)rec).username) {
                String orgId = UserInfo.getOrganizationId();
                ((User)sourceObject).username = ((User)sourceObject).Alias + '@'+ orgId+'.test.com';
            }

            // Add to the factory's list of records created and return the result for this record
            add(sourceObject);

            return (sObject) sourceObject;
        }
    }
}