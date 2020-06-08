
System.Savepoint s = Database.setSavepoint();

c_TestFactory.setDefaultContext();
    

// Making an account hierarchy
// - Build Top Level Accounts

Account[] topLevelList = new List<Account>();
integer totalParentAccounts = 50;
integer totalChildAccounts = 2;

for (Integer i=0; i < totalParentAccounts; i++) {
    Account a = (Account) c_TestFactory.make( new c_TestFactory_SalesCloud.SalesAccount(), new Account(name = 'Top level ' + i));
    Contact c = (Contact) c_TestFactory.make( new c_TestFactory_SalesCloud.SalesContact(), new Contact(FirstName = 'George', LastName = 'Boy' + i));
    Opportunity o = (Opportunity) c_TestFactory.make( new c_TestFactory_SalesCloud.SalesOpportunity(), new Opportunity(name='Opty ' + i));
    Account b = (Account) c_TestFactory.make( new c_TestFactory_SalesCloud.SalesAccount(), new Account(name = 'Extra Account ' + i));
    
    topLevelList.add(a);
}

System.assertEquals(totalParentAccounts, topLevelList.size(), 'Top level group accounts not generated');

// Upsert all data queued so far. We need the top level accounts to create their child records or the DML will get confused. 
// - This is only the case when referencing the same sObject type in one dml transaction...
c_TestFactory.run(); 

//*
// Build some complex Customers using the Customer example object (Accounts with contacts and optys) provided by the framework
// - Instantiate them and parent them to the top level. Note that this only comumes one DML per object type, thus keeping your DML consumption under control when creating large amounts of data.

for (Account topLevel : topLevelList) {
    for (Integer i=0; i < totalChildAccounts; i++) {
        c_TestFactory.make(new c_TestFactory_SalesCloud.Customer(), new Account(name = topLevel.name + ' Customer ' + i, ShippingCity='City'+i, Parent = topLevel));
    }
}

// Upsert the lower level customers (accounts and contacts)
c_TestFactory.run(); 
//*/
Database.rollback(s);