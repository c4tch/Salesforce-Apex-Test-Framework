public with sharing class DemoVestasObjects {
     /*** Asset ***/
     public class DemoAsset extends c_TestFactoryObject {
        sObject defaults() {

            // Default object
            Account rec = new Account();

            // Default values
            rec.Name = 'A Wind Turbine';

            return (sObject) rec;
        }
    }
}
