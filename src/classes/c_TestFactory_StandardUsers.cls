/**
 * @File Name          : c_TestFactory_StandardUsers.cls
 * @Description        : Provides standard users to extend or inherrit from
 * @Author             : Matthew Evans
 * @Group              : 
 * @Last Modified By   : Matthew Evans
 * @Last Modified On   : 12/17/2019, 12:13:35 PM
 * @Modification Log   : 
 * Ver    Date         Author           Modification
 * 1.0    12/17/2019   Matthew Evans    Initial Version
**/

public class c_TestFactory_StandardUsers {

    /**
    * Standard User 
    **/
    public class StandardUser extends c_TestFactoryMaker  {

        sObject defaults()
        {
            // Default object
            User rec = new User();
            String orgId = UserInfo.getOrganizationId();
            
            // Default values
            rec.Alias = 'SysAdmin';
            rec.UserName = rec.Alias + '@'+ orgId+'.anytest.com';
            rec.ProfileId = profileIdByName('Standard User');

            rec.Email = rec.Alias + '@any.test.com';
            rec.FirstName = 'Admin';
            rec.LastName = 'User';

            rec.EmailEncodingKey = EMAIL_ENCODING_KEY; // Context values taken from the Factory
            rec.LanguageLocaleKey = LANGUAGE_LOCALE_KEY;
            rec.LocaleSidKey = LOCALE_SID_KEY;
            rec.TimeZoneSidKey = TIMEZONE_SID_KEY;

            return (sObject) rec;
        }

        // Custom maker method allowing us to set the username based on any custom alias value provided
        // making it easier to identify records created
        public override sObject make(sObject sourceObject) {

            // get and merge defaults
            sObject rec = (sObject) defaults();
            sourceObject = mergeFields(rec, sourceObject);

            // Custom logic to Update the username based on Alias if it's not the same as the default
            if (((User)sourceObject).Alias!=null && ((User)sourceObject).username == ((User)rec).username) {
                String orgId = UserInfo.getOrganizationId();
                ((User)sourceObject).username = ((User)sourceObject).Alias + '@'+ orgId+'.anytest.com';
            }

            // Add to the Templates's list of records created and return the result for this record
            add(sourceObject);

            return (sObject) sourceObject;
        }
    }


    /**
    * Administrator - An example of inherriting from another object
    **/
    public class StandardSystemAdmin extends c_TestFactoryMaker  {

        sObject defaults() {
            // Default object
            User rec = new User();
            rec.Alias = 'SysAdmin';
            rec.ProfileId = profileIdByName('System Administrator');
            return (sObject) rec;
        }
        public override sObject make(sObject sourceObject) {
            // Use the admin defaults and merge them with a standard user so we dont have to repeat code
            sObject rec = (sObject) defaults();
            sourceObject = mergeFields(rec, sourceObject);
            c_Testfactory.make(Entity.STANDARD_USER, sourceObject); // no need to call 'add' next as the make method does this for us
            return sourceObject;
        }
    }

    /**
    * ReadOnly - An example of inherriting only the defaults from another object
    **/
    public class ReadOnly extends c_TestFactoryMaker  {

        sObject defaults() {
            // Use another objects default values using c_Testfactory.getDefauts(); 
            // Do this when you only want to clone the default values from another object
            // but you DON'T want to inherrit any custom "make" logic like in the Standard System Admin example above.
            // In this case we will just choose a diffent profile and stick with the standard "make" - implementing no custom logic.
            User rec = (User)c_Testfactory.getDefaults(Entity.STANDARD_USER);
            rec.ProfileId = profileIdByName('Read Only');
            return (sObject) rec;
        }
    }
    //*/
}